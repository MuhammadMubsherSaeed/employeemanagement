from django.core.exceptions import ImproperlyConfigured

from .base import *
from .env import env

DEBUG = False

SECRET_KEY = env("DJANGO_SECRET_KEY")
if not SECRET_KEY or SECRET_KEY.startswith("dev-"):
    raise ImproperlyConfigured(
        "DJANGO_SECRET_KEY must be set to a strong value in production."
    )

ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS")
if not ALLOWED_HOSTS or ALLOWED_HOSTS == ["*"]:
    raise ImproperlyConfigured(
        "DJANGO_ALLOWED_HOSTS must be a non-wildcard list in production."
    )

postgres_password = env("POSTGRES_PASSWORD", default="")
if not postgres_password:
    raise ImproperlyConfigured("POSTGRES_PASSWORD must be set in production.")
DATABASES["default"]["PASSWORD"] = postgres_password
DATABASES["default"]["CONN_MAX_AGE"] = 60

CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS")
if not CORS_ALLOWED_ORIGINS:
    raise ImproperlyConfigured(
        "CORS_ALLOWED_ORIGINS must be set in production."
    )
CORS_ALLOW_ALL_ORIGINS = False

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"

SPECTACULAR_SETTINGS["SERVE_PERMISSIONS"] = [
    "rest_framework.permissions.IsAdminUser",
]

LOGGING["root"]["level"] = "INFO"
LOGGING["handlers"]["console"]["formatter"] = "verbose"
LOGGING["loggers"]["django.request"]["level"] = "ERROR"
