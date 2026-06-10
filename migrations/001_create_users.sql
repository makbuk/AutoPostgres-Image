-- ============================================================
-- Migration 001: users table
-- ============================================================
-- Files in /docker-entrypoint-initdb.d/ are executed by Postgres
-- AUTOMATICALLY on the FIRST container start, in alphabetical order.
-- Hence the numeric prefixes 001_, 002_ ... — they guarantee order.
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id          BIGSERIAL    PRIMARY KEY,            -- auto-increment ID
    username    VARCHAR(50)  NOT NULL UNIQUE,         -- unique login
    email       VARCHAR(255) NOT NULL UNIQUE,         -- unique email
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()   -- registration date (with timezone)
);

-- Index on email speeds up lookup/login by email.
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
