# AutoPostgres-Image

Pet project: when the SQL schema changes in the repository, GitHub Actions
automatically builds a PostgreSQL Docker image with the fresh schema and pushes
it to Docker Hub — `docker.io/makbuk/autopostgres-image:latest`.

## Project structure

```
AutoPostgres-Image/
├── migrations/
│   ├── 001_create_users.sql      # users table
│   └── 002_create_posts.sql      # posts table + relation to users + demo data
├── Dockerfile                    # postgres:16-alpine image + schema copy
├── docker-compose.yml            # local run for testing
├── .dockerignore
├── .gitignore
└── .github/workflows/
    └── build-and-push.yml        # CI/CD pipeline
```

## How it works

1. On first start, Postgres runs every `.sql` file from
   `/docker-entrypoint-initdb.d/` (alphabetically — hence the `001_`, `002_` prefixes).
2. The Dockerfile copies the `migrations/` folder there.
3. The workflow triggers on `push` to `main` when `migrations/**`,
   `Dockerfile` or the workflow itself change → builds and pushes the image.

## Required secrets

Publishing goes to **Docker Hub**, so you need to add **two secrets** in GitHub:
**Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value |
|---|---|
| `DOCKERHUB_USERNAME` | `makbuk` (your Docker Hub login) |
| `DOCKERHUB_TOKEN` | Access Token from Docker Hub (**not the password!**) |

How to get the token: Docker Hub → **Account Settings → Personal access tokens → Create access token**,
**Read & Write** permissions → copy the value (shown only once).

> The `makbuk/autopostgres-image` repository must exist on Docker Hub (or it will be created
> automatically on the first push if the token has write permissions).

## Local test (before pushing)

```bash
# Build and run
docker compose up --build

# In another terminal — connect to the DB and check the schema
docker compose exec db psql -U app -d appdb -c "\dt"
docker compose exec db psql -U app -d appdb -c "SELECT u.username, p.title FROM users u JOIN posts p ON p.author_id = u.id;"

# Stop and remove the container (data is kept in the pgdata volume)
docker compose down

# Wipe everything, including the volume, and re-seed the schema next start
docker compose down -v
```

You should see the `users` and `posts` tables and the related demo data.

Data is persisted in the named `pgdata` volume, so rows you add survive
`docker compose down` and `up`. To reset the database back to the seeded
schema, remove the volume with `docker compose down -v`.

## Full CI/CD test

1. Create an empty GitHub repository named `AutoPostgres-Image`.
2. Push the code:
   ```bash
   git init
   git add .
   git commit -m "init: postgres image + ci"
   git branch -M main
   git remote add origin git@github.com:makbuk/AutoPostgres-Image.git
   git push -u origin main
   ```
3. Open the **Actions** tab — the pipeline runs automatically.
4. On success the image appears on Docker Hub: **https://hub.docker.com/r/makbuk/autopostgres-image/tags**
   with the `latest` tag.

### Testing the auto-trigger on a schema change

```bash
# Add a new migration
cat > migrations/003_add_comments.sql <<'SQL'
CREATE TABLE IF NOT EXISTS comments (
    id        BIGSERIAL PRIMARY KEY,
    post_id   BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    body      TEXT   NOT NULL
);
SQL

git add migrations/003_add_comments.sql
git commit -m "feat: add comments table"
git push
```

→ Actions runs again and builds a new image with the `latest` tag.

### Running the published image

```bash
# If the makbuk/autopostgres-image repository is public — no login needed.
# The -v flag persists data in a named volume so it survives container removal:
docker run -d -p 5432:5432 \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=appdb \
  -v autopostgres_data:/var/lib/postgresql/data \
  makbuk/autopostgres-image:latest

# If private — log in first:
echo <DOCKERHUB_TOKEN> | docker login -u makbuk --password-stdin
```
