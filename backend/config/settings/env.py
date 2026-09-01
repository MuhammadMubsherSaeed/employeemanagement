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
    EMAIL_PORT=(int, 587),
    EMAIL_USE_TLS=(bool, True),
    PASSWORD_RESET_TIMEOUT=(int, 60 * 60 * 24),
    MAX_DOCUMENT_UPLOAD_SIZE=(int, 10 * 1024 * 1024),
    DOCUMENT_EXPIRING_SOON_DAYS=(int, 30),
    LEAVE_ATTACHMENT_MAX_BYTES=(int, 5 * 1024 * 1024),
    MAX_PROFILE_IMAGE_UPLOAD_SIZE=(int, 2 * 1024 * 1024),
    AWS_QUERYSTRING_EXPIRE=(int, 300),
)

_env_file = BASE_DIR / ".env"
if _env_file.exists():
    environ.Env.read_env(os.path.join(BASE_DIR, ".env"))
