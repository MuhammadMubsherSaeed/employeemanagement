from .base import *
from .env import env

DEBUG = env.bool("DJANGO_DEBUG", default=True)

SECRET_KEY = env(
    "DJANGO_SECRET_KEY",
    default="dev-only-insecure-key-do-not-use-in-production",
)

ALLOWED_HOSTS = env.list(
    "DJANGO_ALLOWED_HOSTS",
    default=["localhost", "127.0.0.1"],
)

CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
    ],
)
CORS_ALLOW_ALL_ORIGINS = False

DATABASES["default"]["CONN_MAX_AGE"] = 0

REST_FRAMEWORK["DEFAULT_RENDERER_CLASSES"] = (
    "rest_framework.renderers.JSONRenderer",
    "rest_framework.renderers.BrowsableAPIRenderer",
)

SPECTACULAR_SETTINGS["SERVE_PERMISSIONS"] = [
    "rest_framework.permissions.AllowAny",
]

REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {
    "auth_login": "120/min",
    "auth_refresh": "120/min",
    "auth_password": "60/min",
}

EMAIL_BACKEND = env(
    "EMAIL_BACKEND",
    default="django.core.mail.backends.console.EmailBackend",
)

LOGGING["root"]["level"] = "DEBUG"
LOGGING["loggers"]["apps"]["level"] = "DEBUG"
LOGGING["handlers"]["console"]["formatter"] = "console"
