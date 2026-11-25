-- Виконується автоматично лише при першій ініціалізації порожнього тому БД.

CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    city          TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS books (
    id         SERIAL PRIMARY KEY,
    owner_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      TEXT NOT NULL,
    author     TEXT NOT NULL,
    status     TEXT NOT NULL DEFAULT 'available'
               CHECK (status IN ('available', 'reserved', 'exchanged')),
    cover_key  TEXT,                      -- ключ об'єкта в S3
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS swap_requests (
    id           SERIAL PRIMARY KEY,
    book_id      INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    requester_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_books_owner ON books(owner_id);
CREATE INDEX IF NOT EXISTS idx_users_city ON users(city);
