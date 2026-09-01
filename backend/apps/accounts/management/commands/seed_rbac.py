from django.core.management.base import BaseCommand

from apps.accounts.models import Permission, Role
from apps.accounts.rbac_catalog import PERMISSION_META, ROLE_DEFINITIONS
from apps.accounts.services.permissions import apply_role_permissions


class Command(BaseCommand):
    help = "Create or update default roles, permissions, and bindings (idempotent)."

    def handle(self, *args, **options):
        for code, (name, module) in PERMISSION_META.items():
            Permission.objects.update_or_create(
                code=code,
                defaults={
                    "name": name,
                    "module": module,
                    "description": name,
                },
            )

        for definition in ROLE_DEFINITIONS:
            role, _created = Role.objects.update_or_create(
                code=definition["code"],
                scope=definition["scope"],
                defaults={
                    "name": definition["name"],
                    "description": definition["description"],
                    "is_system_role": True,
                },
            )
            apply_role_permissions(role, definition["permissions"])

        self.stdout.write(self.style.SUCCESS("RBAC defaults are up to date."))
