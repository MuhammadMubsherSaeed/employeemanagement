"""Load environment variables for Django settings."""

from __future__ import annotations

import os
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(list, []),
    POSTGRES_PORT=(int, 5432),
    JWT_ACCESS_MINUTES=(int, 15),
    JWT_REFRESH_DAYS=(int, 7),
)

_env_file = BASE_DIR / ".env"
if _env_file.exists():
    environ.Env.read_env(os.path.join(BASE_DIR, ".env"))
