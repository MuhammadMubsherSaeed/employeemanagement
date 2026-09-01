from django.db import transaction
from django.test import RequestFactory, TestCase, TransactionTestCase
from django.core.management import call_command

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.models import AuditLog
from apps.audit_logs.sanitize import REDACTED, sanitize_audit_value
from apps.audit_logs.services import AuditService, create_audit_log
from apps.companies.models import Company
from apps.companies.tests.fixtures import TenancyFixtureMixin


class AuditServiceTests(TenancyFixtureMixin, TestCase):
    def setUp(self) -> None:
        self.factory = RequestFactory()

    def test_create_audit_log_stores_actor_and_json(self) -> None:
        log = create_audit_log(
            company=self.company_a,
            user=self.admin_a,
            action=AuditAction.EMPLOYEE_UPDATED,
            entity_type=AuditEntityType.EMPLOYEE,
            entity_id=42,
            old_value={"status": "ACTIVE"},
            new_value={"status": "INACTIVE"},
        )
        self.assertEqual(log.user_id, self.admin_a.id)
        self.assertEqual(log.entity_id, "42")
        self.assertEqual(log.old_value, {"status": "ACTIVE"})
        self.assertIsNone(log.ip_address)
        self.assertIsNone(log.user_agent)

    def test_extracts_ip_and_user_agent_from_request(self) -> None:
        request = self.factory.get(
            "/",
            REMOTE_ADDR="203.0.113.10",
            HTTP_USER_AGENT="AuditClient/1.0",
        )
        log = AuditService.log(
            company=self.company_a,
            user=self.admin_a,
            action=AuditAction.EMPLOYEE_CREATED,
            entity_type=AuditEntityType.EMPLOYEE,
            entity_id="1",
            request=request,
        )
        self.assertEqual(log.ip_address, "203.0.113.10")
        self.assertEqual(log.user_agent, "AuditClient/1.0")

    def test_does_not_trust_forwarded_for(self) -> None:
        request = self.factory.get(
            "/",
            REMOTE_ADDR="10.0.0.8",
            HTTP_X_FORWARDED_FOR="198.51.100.1, 10.0.0.8",
        )
        log = AuditService.log(
            company=self.company_a,
            action=AuditAction.EMPLOYEE_CREATED,
            entity_type=AuditEntityType.EMPLOYEE,
            entity_id="1",
            request=request,
        )
        self.assertEqual(log.ip_address, "10.0.0.8")

    def test_nullable_request_metadata_does_not_fail(self) -> None:
        log = AuditService.log(
            company=self.company_a,
            action=AuditAction.EMPLOYEE_CREATED,
            entity_type=AuditEntityType.EMPLOYEE,
            entity_id="1",
            request=None,
        )
        self.assertIsNone(log.ip_address)
        self.assertIsNone(log.user_agent)

    def test_redacts_sensitive_fields(self) -> None:
        log = AuditService.log(
            company=self.company_a,
            action=AuditAction.EMPLOYEE_UPDATED,
            entity_type=AuditEntityType.USER,
            entity_id=str(self.admin_a.id),
            old_value={
                "email": "admin-a@example.com",
                "password": "plain-secret",
                "nested": {"refresh_token": "jwt-refresh", "role": "EMPLOYEE"},
            },
            new_value={
                "password_hash": "pbkdf2$...",
                "access_token": "aaa.bbb.ccc",
                "api_key": "sk-live",
                "client_secret": "oauth-secret",
            },
        )
        self.assertEqual(log.old_value["password"], REDACTED)
        self.assertEqual(log.old_value["nested"]["refresh_token"], REDACTED)
        self.assertEqual(log.old_value["nested"]["role"], "EMPLOYEE")
        self.assertEqual(log.new_value["password_hash"], REDACTED)
        self.assertEqual(log.new_value["access_token"], REDACTED)
        self.assertEqual(log.new_value["api_key"], REDACTED)
        self.assertEqual(log.new_value["client_secret"], REDACTED)
        self.assertNotIn("plain-secret", str(log.old_value))
        self.assertNotIn("jwt-refresh", str(log.old_value))

    def test_sanitize_helper_covers_payment_and_credentials(self) -> None:
        cleaned = sanitize_audit_value(
            {
                "card_number": "4111111111111111",
                "cvv": "123",
                "credentials": {"user": "x", "password": "y"},
            }
        )
        self.assertEqual(cleaned["card_number"], REDACTED)
        self.assertEqual(cleaned["cvv"], REDACTED)
        self.assertEqual(cleaned["credentials"], REDACTED)
        cleaned_urls = sanitize_audit_value(
            {
                "signed_url": "https://bucket.example/key?X-Amz-Signature=secret",
                "download_url": "https://example/file?token=abc",
                "file_name": "cnic.pdf",
            }
        )
        self.assertEqual(cleaned_urls["signed_url"], REDACTED)
        self.assertEqual(cleaned_urls["download_url"], REDACTED)
        self.assertEqual(cleaned_urls["file_name"], "cnic.pdf")


class AuditServiceTransactionTests(TransactionTestCase):
    def test_rollback_drops_audit_log(self) -> None:
        call_command("seed_rbac", verbosity=0)
        company = Company.objects.create(name="Txn Co", slug="txn-co")
        try:
            with transaction.atomic():
                AuditService.log(
                    company=company,
                    action=AuditAction.EMPLOYEE_CREATED,
                    entity_type=AuditEntityType.EMPLOYEE,
                    entity_id="rollback",
                )
                raise RuntimeError("boom")
        except RuntimeError:
            pass
        self.assertFalse(
            AuditLog.objects.filter(company=company, entity_id="rollback").exists()
        )

    def test_committed_transaction_persists_audit_log(self) -> None:
        call_command("seed_rbac", verbosity=0)
        company = Company.objects.create(name="Commit Co", slug="commit-co")
        with transaction.atomic():
            AuditService.log(
                company=company,
                action=AuditAction.EMPLOYEE_CREATED,
                entity_type=AuditEntityType.EMPLOYEE,
                entity_id="commit",
            )
        self.assertTrue(
            AuditLog.objects.filter(company=company, entity_id="commit").exists()
        )
