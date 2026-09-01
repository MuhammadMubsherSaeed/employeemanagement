from apps.employees.tests.fixtures import EmployeeFixtureMixin
from apps.notifications.models import Notification, NotificationType

NOTIFICATIONS = "/api/v1/notifications"
TOKENS = "/api/v1/notifications/device-tokens"


class NotificationFixtureMixin(EmployeeFixtureMixin):
    def make_notification(self, recipient, company=None, **kwargs) -> Notification:
        defaults = {
            "company": company or recipient.get_active_membership().company,
            "recipient": recipient,
            "type": NotificationType.SYSTEM,
            "title": "System notice",
            "message": "A system notification.",
        }
        defaults.update(kwargs)
        return Notification.objects.create(**defaults)
