from django.core.management.base import BaseCommand

from apps.accounts.models import Permission, Role
from apps.accounts.rbac_catalog import PERMISSION_META, ROLE_DEFINITIONS


class Command(BaseCommand):
    help = "Create or update default roles, permissions, and bindings (idempotent)."

    def handle(self, *args, **options):
        permission_by_code = {}
        for code, (name, module) in PERMISSION_META.items():
            permission, _created = Permission.objects.update_or_create(
                code=code,
                defaults={
                    "name": name,
                    "module": module,
                    "description": name,
                },
            )
            permission_by_code[code] = permission

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
            if definition["permissions"]:
                role.permissions.set(
                    permission_by_code[code] for code in definition["permissions"]
                )
            else:
                role.permissions.clear()

        self.stdout.write(self.style.SUCCESS("RBAC defaults are up to date."))
