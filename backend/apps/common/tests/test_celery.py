from django.test import SimpleTestCase

from apps.common.tasks import ping
from config.celery import app


class CeleryConfigTests(SimpleTestCase):
    def test_ping_task_is_registered(self) -> None:
        self.assertEqual(ping.name, "apps.common.ping")
        self.assertIn(ping.name, app.tasks)
        self.assertEqual(ping(), "ok")
