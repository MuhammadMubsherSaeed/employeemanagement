from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.test import TestCase
from django.utils import timezone

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.companies.tests.fixtures import TenancyFixtureMixin


class AuditLogModelTests(TenancyFixtureMixin, TestCase):
    def test_creates_with_required_company_and_json_values(self) -> None:
        before = timezone.now()
        log = AuditLog.objects.create(
            company=self.company_a,
            user=self.admin_a,
            action=AuditAction.EMPLOYEE_CREATED,
            entity_type=AuditEntityType.EMPLOYEE,
            entity_id="abc-123",
            old_value=None,
            new_value={"status": "ACTIVE", "department": "Engineering"},
        )
        self.assertEqual(log.company_id, self.company_a.id)
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertEqual(log.action, AuditAction.EMPLOYEE_CREATED)
        self.assertEqual(log.entity_type, AuditEntityType.EMPLOYEE)
        self.assertEqual(log.entity_id, "abc-123")
        self.assertEqual(log.new_value["department"], "Engineering")
        self.assertGreaterEqual(log.created_at, before)
        self.assertIsNotNone(log.created_at.tzinfo)

    def test_user_may_be_null(self) -> None:
        log = AuditLog.objects.create(
            company=self.company_a,
            user=None,
            action=AuditAction.SETTINGS_CHANGED,
            entity_type=AuditEntityType.COMPANY_SETTINGS,
            entity_id="settings-1",
        )
        self.assertIsNone(log.user_id)

    def test_company_is_required(self) -> None:
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                AuditLog.objects.create(
                    company=None,
                    action=AuditAction.EMPLOYEE_CREATED,
                    entity_type=AuditEntityType.EMPLOYEE,
                    entity_id="1",
                )

    def test_invalid_action_and_entity_type_are_rejected(self) -> None:
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                AuditLog.objects.create(
                    company=self.company_a,
                    action="NOT_A_REAL_ACTION",
                    entity_type=AuditEntityType.EMPLOYEE,
                    entity_id="1",
                )
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                AuditLog.objects.create(
                    company=self.company_a,
                    action=AuditAction.EMPLOYEE_CREATED,
                    entity_type="POSITION",
                    entity_id="1",
                )

    def test_cannot_update_or_delete(self) -> None:
        log = AuditLog.objects.create(
            company=self.company_a,
            action=AuditAction.EMPLOYEE_CREATED,
            entity_type=AuditEntityType.EMPLOYEE,
            entity_id="1",
        )
        log.action = AuditAction.EMPLOYEE_UPDATED
        with self.assertRaises(ValidationError):
            log.save()
        with self.assertRaises(ValidationError):
            log.delete()
        with self.assertRaises(ValidationError):
            AuditLog.objects.filter(pk=log.pk).update(action=AuditAction.EMPLOYEE_UPDATED)

    def test_query_indexes_cover_list_filters(self) -> None:
        names = {index.name for index in AuditLog._meta.indexes}
        self.assertTrue(any("company" in (index.fields or []) for index in AuditLog._meta.indexes))
        self.assertGreaterEqual(len(names), 5)
