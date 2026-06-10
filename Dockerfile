# ============================================================
# PostgreSQL image with the DB schema already baked in.
# ============================================================
# Start from the official Postgres image. We pin the tag (16-alpine)
# so builds are reproducible and the image stays small.
FROM postgres:16-alpine

# Image metadata (optional, but useful).
LABEL org.opencontainers.image.description="PostgreSQL with a preinstalled users/posts schema"
LABEL org.opencontainers.image.source="https://github.com/makbuk/AutoPostgres-Image"

# Copy all .sql migrations into the special init directory.
# IMPORTANT: Postgres runs these scripts automatically on the FIRST
# container start (when the data directory PGDATA is still empty).
# If you mount a volume with existing data, the scripts will NOT re-run.
COPY migrations/ /docker-entrypoint-initdb.d/

# Default port (documentation directive; actual mapping is done at run time).
EXPOSE 5432

# CMD/ENTRYPOINT are inherited from the base postgres image — no need to override.
