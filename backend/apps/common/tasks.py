from celery import shared_task


@shared_task(name="apps.common.ping")
def ping() -> str:
    """Used to verify the worker is processing. Not a product workflow."""
    return "ok"
