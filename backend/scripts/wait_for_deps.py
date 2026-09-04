"""Wait until TCP dependencies accept connections. No secrets are printed."""

from __future__ import annotations

import os
import socket
import sys
import time
from urllib.parse import urlparse


def _wait_tcp(host: str, port: int, retries: int, delay: float) -> None:
    last_error = "unreachable"
    for _attempt in range(retries):
        try:
            with socket.create_connection((host, port), timeout=2):
                return
        except OSError as exc:
            last_error = str(exc)
            time.sleep(delay)
    print(f"Dependency {host}:{port} is not ready ({last_error}).", file=sys.stderr)
    raise SystemExit(1)


def _redis_target(url: str) -> tuple[str, int] | None:
    parsed = urlparse(url)
    if not parsed.hostname:
        return None
    return parsed.hostname, parsed.port or 6379


def main() -> None:
    retries = int(os.environ.get("DEPENDENCY_WAIT_RETRIES", "30"))
    delay = float(os.environ.get("DEPENDENCY_WAIT_DELAY", "1"))
    db_host = os.environ.get("DB_HOST") or os.environ.get("POSTGRES_HOST") or ""
    db_port = int(os.environ.get("DB_PORT") or os.environ.get("POSTGRES_PORT") or "5432")
    if db_host:
        _wait_tcp(db_host, db_port, retries, delay)

    redis_url = os.environ.get("REDIS_URL") or os.environ.get("CELERY_BROKER_URL") or ""
    target = _redis_target(redis_url)
    if target is not None:
        _wait_tcp(target[0], target[1], retries, delay)


if __name__ == "__main__":
    main()
