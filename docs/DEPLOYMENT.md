# Production deployment — Django HRMS API

This repository ships a production Docker stack:

```text
Internet
   ↓
Nginx :80 (TLS-ready)
   ↓
Gunicorn
   ↓
Django
   ↓
PostgreSQL (internal)

Django / Celery worker
   ↓
Redis (internal, password-protected)
```

Local `runserver` development remains available as `docker-compose.dev.yml`. Do not use it in production.

Celery Beat is **not** enabled. The application has no periodic tasks yet. Add a single `celery_beat` service only after scheduled jobs exist.

---

## Requirements

- Docker Engine 24+
- Docker Compose v2
- A Linux or Windows host with at least 2 vCPU / 4 GB RAM (small team)
- A domain name when exposing the API beyond localhost
- TLS certificates when serving HTTPS (Let's Encrypt, cloud load balancer, or similar)

---

## Environment and secrets

1. Copy [`.env.example`](../.env.example) to `.env` at the **repository root**.
2. Replace every `change-me` value. Use a long random `DJANGO_SECRET_KEY` and strong `POSTGRES_PASSWORD` / `REDIS_PASSWORD`.
3. Set `DJANGO_ALLOWED_HOSTS` to the public hostname plus `localhost,127.0.0.1,web` (needed for container health checks).
4. Set `CORS_ALLOWED_ORIGINS` to the real Flutter / web origins. Never `*` in production.
5. Keep `.env` out of Git. It is already gitignored.

`REDIS_PASSWORD` must be URL-safe (letters, numbers, `-` `_`). Compose builds `REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0`.

Django also accepts `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, and `DB_PORT` as aliases of the existing `POSTGRES_*` names.

---

## Build and start

From the repository root:

```bash
cp .env.example .env
# edit .env

docker compose build
docker compose up -d
docker compose ps
```

Nginx is the only published port (`NGINX_HTTP_PORT`, default 80). PostgreSQL and Redis are not published.

Useful logs:

```bash
docker compose logs -f
docker compose logs -f web
docker compose logs -f celery_worker
docker compose logs -f nginx
```

---

## Migrations and static files

The `web` container runs migrate and collectstatic on startup when `RUN_STARTUP_TASKS=1` (the default for that service). That is safe for a **single** web replica.

With multiple web replicas, set `RUN_STARTUP_TASKS=0` on the web service and run once:

```bash
docker compose exec web python manage.py migrate --noinput
docker compose exec web python manage.py collectstatic --noinput
```

Never run `flush`, `reset_db`, or recreate volumes as part of a normal deploy.

Create a Django superuser only when needed:

```bash
docker compose exec web python manage.py createsuperuser
```

---

## Health check

```bash
curl -fsS http://127.0.0.1/api/v1/health/
```

Expected:

```json
{"success": true, "message": "API is healthy.", "data": {"status": "ok"}}
```

The endpoint checks PostgreSQL. If `REDIS_URL` is configured, it also pings Redis. Failures return HTTP 503 without hostnames or credentials.

Authenticated smoke test (use a staging user, not production secrets in shell history if avoidable):

```bash
curl -fsS -X POST http://127.0.0.1/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"staging-admin@example.com","password":"..."}'
```

---

## Static files and media

| Kind | How it is served |
| --- | --- |
| Django / admin static | Nginx `/static/` from the `static_files` volume |
| Employee documents, profile images, leave attachments | Authenticated API only. **Not** aliased under `/media/` |
| Production files | Set `STORAGE_BACKEND=s3` and the `AWS_*` variables |

Local Docker `STORAGE_BACKEND=local` stores objects on the `media_files` volume as a fallback. That is not a public CDN.

---

## HTTPS / SSL

1. Obtain certificates (not self-signed for production).
2. Mount `fullchain.pem` and `privkey.pem` into `docker/nginx/certs/` (or a secret volume). Do not commit keys.
3. Replace `docker/nginx/conf.d/default.conf` with the contents of `docker/nginx/conf.d/ssl.conf.example` (adjust `server_name`).
4. Publish `443:443` on the `nginx` service.
5. Set in `.env`:

```text
DJANGO_SECURE_SSL_REDIRECT=True
CSRF_TRUSTED_ORIGINS=https://example.com
CORS_ALLOWED_ORIGINS=https://example.com
FRONTEND_PASSWORD_RESET_URL=https://example.com/reset-password
```

Until TLS terminates at Nginx, leave `DJANGO_SECURE_SSL_REDIRECT=False` so HTTP Docker deploys stay reachable.

---

## Celery

The worker uses the same application image:

```bash
docker compose logs -f celery_worker
docker compose exec celery_worker celery -A config.celery inspect ping
```

There is no Beat process. When a scheduled job is added, introduce **one** `celery_beat` service and a persistent scheduler volume. Do not run two Beat instances.

---

## Backups

PostgreSQL data lives in the `postgres_data` volume. Suggested baseline:

| Item | Recommendation |
| --- | --- |
| Frequency | Daily logical dump; more often if the HR data changes constantly |
| Command | `docker compose exec -T db pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > hrms-$(date +%F).sql` |
| Retention | Keep at least 7 daily and 4 weekly copies off-host |
| Restore test | Restore into a throwaway database at least quarterly |
| Object storage | If `STORAGE_BACKEND=s3`, use the provider's versioning + bucket backup. Local `media_files` should be copied with the database dump |

Do not rely on an untested dump. Encrypt backups at rest.

Restore sketch (destructive — only on a recovery host):

```bash
docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < hrms-YYYY-MM-DD.sql
```

---

## Updates

1. `git fetch` and check out the release.
2. `docker compose build`
3. Take a database dump.
4. `docker compose up -d`
5. Confirm `docker compose ps` (all healthy) and `/api/v1/health/`.
6. Spot-check login and one authenticated list endpoint.

If migrate/collectstatic are not run by the entrypoint, run them once after `up`.

---

## Rollback

1. Keep the previous image tag or Git revision.
2. Restore the matching database dump if migrations are not backward compatible.
3. `docker compose up -d` with the previous image.
4. Do not `migrate` forward and then “undo” by deleting migration files.

---

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Database unavailable | `docker compose ps db`, `docker compose logs db`, `POSTGRES_PASSWORD` matches Django |
| Redis unavailable | `docker compose logs redis`, URL-safe `REDIS_PASSWORD`, health `/api/v1/health/` 503 |
| Celery idle | Worker logs, Redis ping, `celery -A config inspect ping` |
| Nginx 502 | `web` healthy? Gunicorn listening on 8000? `docker compose logs web` |
| Static 404 | collectstatic ran? `static_files` volume mounted on nginx and web |
| Migration failure | Read the migrate error; fix data; do not drop the volume |
| Missing env | Compose refuses to start if `POSTGRES_PASSWORD` or `REDIS_PASSWORD` is unset |
| Redirect loop | `DJANGO_SECURE_SSL_REDIRECT` is True but Nginx is HTTP-only |
| Host header rejected | Add the public hostname and `web,localhost,127.0.0.1` to `DJANGO_ALLOWED_HOSTS` |

---

## Django checks (from a venv or `web` container)

```bash
docker compose exec web python manage.py check
docker compose exec web python manage.py check --deploy
docker compose exec web python manage.py showmigrations
```

`check --deploy` warns while TLS is off (`SECURE_SSL_REDIRECT`, HSTS, secure cookies). Enable those flags after HTTPS is in place. Spectacular schema warnings (W001/W002) are pre-existing OpenAPI hints, not deploy blockers.

---

## Local development Compose

Postgres **is** published on the host (port 5432) for this file only:

```bash
docker compose -f docker-compose.dev.yml up --build
```

---

## Remaining external work

These are not provided by this repository:

- DNS for the API hostname
- TLS certificates
- Cloud firewall (allow 80/443 only)
- Production S3/R2 credentials when leaving local media
- SMTP credentials
- Firebase / FCM credentials if push is required
- Off-host backup storage and monitoring (Sentry, uptime checks)
