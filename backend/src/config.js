// 12-Factor, фактор III: уся конфігурація береться ТІЛЬКИ зі змінних оточення.
// Обов'язкові змінні без значень за замовчуванням: застосунок не стартує, якщо їх немає.

function required(name) {
  const value = process.env[name];
  if (!value) {
    console.error(`[config] Відсутня обов'язкова змінна оточення: ${name}`);
    process.exit(1);
  }
  return value;
}

const config = {
  port: Number(process.env.PORT || 3000),
  jwtSecret: required('JWT_SECRET'),
  jwtTtl: process.env.JWT_TTL || '2h',
  catalogCacheTtl: Number(process.env.CATALOG_CACHE_TTL || 60),

  db: {
    host: required('DB_HOST'),
    port: Number(process.env.DB_PORT || 5432),
    user: required('DB_USER'),
    password: required('DB_PASSWORD'),
    database: required('DB_NAME'),
  },

  redisUrl: required('REDIS_URL'),

  s3: {
    endpoint: required('S3_ENDPOINT'),
    region: process.env.S3_REGION || 'us-east-1',
    accessKey: required('S3_ACCESS_KEY'),
    secretKey: required('S3_SECRET_KEY'),
    bucket: required('S3_BUCKET'),
  },
};

export default config;
