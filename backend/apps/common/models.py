from django.db import models


class TimeStampedModel(models.Model):
    """Abstract timestamps for future domain models. Timezone-aware via USE_TZ."""

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
