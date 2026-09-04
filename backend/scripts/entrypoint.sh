#!/bin/sh
set -eu

mkdir -p /app/staticfiles /app/media
chown -R app:app /app/staticfiles /app/media

gosu app python scripts/wait_for_deps.py

if [ "${RUN_STARTUP_TASKS:-0}" = "1" ]; then
  gosu app python manage.py migrate --noinput
  gosu app python manage.py collectstatic --noinput
fi

exec gosu app "$@"
