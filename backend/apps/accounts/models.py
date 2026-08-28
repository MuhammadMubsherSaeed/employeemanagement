from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom user required before the first migration.

    Authentication endpoints are intentionally not implemented in this
    initialization step. Role is stored so Admin / Manager / Employee can
    be enforced later without another user-model change.
    """

    class Role(models.TextChoices):
        ADMIN = "admin", "Admin"
        MANAGER = "manager", "Manager"
        EMPLOYEE = "employee", "Employee"

    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.EMPLOYEE,
        db_index=True,
    )

    def __str__(self) -> str:
        return self.get_username()
