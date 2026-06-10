-- ============================================================
-- Migration 002: posts table (one-to-many relation with users)
-- ============================================================
-- A single user can have many posts.
-- The relation is enforced by the foreign key author_id -> users.id.
-- ============================================================

CREATE TABLE IF NOT EXISTS posts (
    id          BIGSERIAL    PRIMARY KEY,
    author_id   BIGINT       NOT NULL,               -- who wrote the post
    title       VARCHAR(200) NOT NULL,
    body        TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

    -- Foreign key: deleting a user also deletes their posts (CASCADE).
    CONSTRAINT fk_posts_author
        FOREIGN KEY (author_id)
        REFERENCES users (id)
        ON DELETE CASCADE
);

-- Index on author_id speeds up the "all posts of a user" query.
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts (author_id);

-- Some demo data so the image is immediately "alive" for testing.
-- (For a production image this section is usually removed.)
INSERT INTO users (username, email) VALUES
    ('alice', 'alice@example.com'),
    ('bob',   'bob@example.com')
ON CONFLICT (username) DO NOTHING;

INSERT INTO posts (author_id, title, body) VALUES
    (1, 'Alice''s first post',  'Hello, world!'),
    (1, 'Alice''s second post', 'PostgreSQL is great'),
    (2, 'Bob''s post',          'CI/CD automates the routine')
ON CONFLICT DO NOTHING;
