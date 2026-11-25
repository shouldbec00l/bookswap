import express from 'express';
import pg from 'pg';
import Redis from 'ioredis';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';
import { S3Client, HeadBucketCommand, CreateBucketCommand } from '@aws-sdk/client-s3';
import config from './config.js';

const pool = new pg.Pool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
});

const redis = new Redis(config.redisUrl, { maxRetriesPerRequest: 3 });

const s3 = new S3Client({
  endpoint: config.s3.endpoint,
  region: config.s3.region,
  forcePathStyle: true, // потрібно для MinIO
  credentials: { accessKeyId: config.s3.accessKey, secretAccessKey: config.s3.secretKey },
});

// ---------- допоміжні функції ----------

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
  const [salt, hash] = stored.split(':');
  const candidate = crypto.scryptSync(password, salt, 64);
  return crypto.timingSafeEqual(candidate, Buffer.from(hash, 'hex'));
}

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Потрібна авторизація' });
  try {
    req.user = jwt.verify(token, config.jwtSecret);
    next();
  } catch {
    res.status(401).json({ error: 'Недійсний токен' });
  }
}

async function invalidateCatalogCache() {
  const keys = await redis.keys('catalog:*');
  if (keys.length) await redis.del(keys);
}

async function ensureBucket() {
  for (let attempt = 1; attempt <= 10; attempt++) {
    try {
      try {
        await s3.send(new HeadBucketCommand({ Bucket: config.s3.bucket }));
      } catch {
        await s3.send(new CreateBucketCommand({ Bucket: config.s3.bucket }));
      }
      console.log(`[s3] Бакет "${config.s3.bucket}" готовий`);
      return;
    } catch (err) {
      console.warn(`[s3] Спроба ${attempt}/10 не вдалась: ${err.message}`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  throw new Error('S3-сховище недоступне');
}

// ---------- застосунок ----------

const app = express();
app.use(express.json());

// Liveness: процес живий
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// Readiness: залежності доступні
app.get('/health/ready', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    await redis.ping();
    res.json({ status: 'ready' });
  } catch (err) {
    res.status(503).json({ status: 'unavailable', error: err.message });
  }
});

app.post('/api/auth/register', async (req, res) => {
  const { email, password, city } = req.body || {};
  if (!email || !password || !city) {
    return res.status(400).json({ error: 'Потрібні email, password, city' });
  }
  try {
    const { rows } = await pool.query(
      'INSERT INTO users (email, password_hash, city) VALUES ($1, $2, $3) RETURNING id, email, city',
      [email, hashPassword(password), city],
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Користувач уже існує' });
    console.error(err);
    res.status(500).json({ error: 'Внутрішня помилка' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];
  if (!user || !verifyPassword(password || '', user.password_hash)) {
    return res.status(401).json({ error: 'Невірний email або пароль' });
  }
  const token = jwt.sign({ sub: user.id, email: user.email }, config.jwtSecret, {
    expiresIn: config.jwtTtl,
  });
  res.json({ token });
});

// Каталог із кешуванням у Redis (cache-aside)
app.get('/api/books', async (req, res) => {
  const city = req.query.city ? String(req.query.city) : 'all';
  const cacheKey = `catalog:${city}`;
  try {
    const cached = await redis.get(cacheKey);
    if (cached) {
      res.set('X-Cache', 'HIT');
      return res.json(JSON.parse(cached));
    }
    const query =
      city === 'all'
        ? `SELECT b.id, b.title, b.author, b.status, u.city
             FROM books b JOIN users u ON u.id = b.owner_id ORDER BY b.id DESC LIMIT 100`
        : `SELECT b.id, b.title, b.author, b.status, u.city
             FROM books b JOIN users u ON u.id = b.owner_id
            WHERE u.city = $1 ORDER BY b.id DESC LIMIT 100`;
    const { rows } = await pool.query(query, city === 'all' ? [] : [city]);
    await redis.set(cacheKey, JSON.stringify(rows), 'EX', config.catalogCacheTtl);
    res.set('X-Cache', 'MISS');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Внутрішня помилка' });
  }
});

app.post('/api/books', auth, async (req, res) => {
  const { title, author } = req.body || {};
  if (!title || !author) return res.status(400).json({ error: 'Потрібні title та author' });
  try {
    const { rows } = await pool.query(
      'INSERT INTO books (owner_id, title, author) VALUES ($1, $2, $3) RETURNING id, title, author, status',
      [req.user.sub, title, author],
    );
    await invalidateCatalogCache();
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Внутрішня помилка' });
  }
});

// ---------- запуск і graceful shutdown (фактор IX) ----------

await ensureBucket();
const server = app.listen(config.port, () => {
  console.log(`[api] Слухаю порт ${config.port}`);
});

async function shutdown(signal) {
  console.log(`[api] Отримано ${signal}, завершую роботу...`);
  server.close(async () => {
    await Promise.allSettled([pool.end(), redis.quit()]);
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10000).unref();
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
