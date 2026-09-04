"""Gunicorn process settings. Tuned via environment variables."""

import multiprocessing
import os

bind = os.environ.get("GUNICORN_BIND", "0.0.0.0:8000")

_default_workers = min(4, (multiprocessing.cpu_count() * 2) + 1)
workers = int(os.environ.get("WEB_CONCURRENCY", str(_default_workers)))
threads = int(os.environ.get("GUNICORN_THREADS", "1"))
worker_class = os.environ.get("GUNICORN_WORKER_CLASS", "sync")

timeout = int(os.environ.get("GUNICORN_TIMEOUT", "90"))
graceful_timeout = int(os.environ.get("GUNICORN_GRACEFUL_TIMEOUT", "30"))
keepalive = int(os.environ.get("GUNICORN_KEEPALIVE", "5"))

max_requests = int(os.environ.get("GUNICORN_MAX_REQUESTS", "1000"))
max_requests_jitter = int(os.environ.get("GUNICORN_MAX_REQUESTS_JITTER", "50"))

accesslog = os.environ.get("GUNICORN_ACCESS_LOG", "-")
errorlog = os.environ.get("GUNICORN_ERROR_LOG", "-")
loglevel = os.environ.get("GUNICORN_LOG_LEVEL", "info")
capture_output = True
enable_stdio_inheritance = True

limit_request_line = 4094
limit_request_fields = 100
forwarded_allow_ips = os.environ.get("GUNICORN_FORWARDED_ALLOW_IPS", "*")
proxy_protocol = False

# Do not log Authorization or cookie values. Gunicorn's default access log
# is method/url/status only when using the default format.
access_log_format = os.environ.get(
    "GUNICORN_ACCESS_LOG_FORMAT",
    '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s',
)
