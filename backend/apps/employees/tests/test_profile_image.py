from tempfile import TemporaryDirectory

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings

from apps.audit_logs.constants import AuditAction
from apps.audit_logs.models import AuditLog
from apps.documents.tests.fixtures import (
    jpeg_file,
    pdf_file,
    png_file,
    read_download,
    uploaded,
)
from apps.employees.tests.fixtures import EMPLOYEES, EmployeeFixtureMixin


def profile_image_url(employee_id) -> str:
    return f"{EMPLOYEES}/{employee_id}/profile-image/"


class ProfileImageAPITests(EmployeeFixtureMixin, TestCase):
    def test_admin_can_upload_replace_download_and_clear(self) -> None:
        client = self.authenticate(self.admin_a)
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media, STORAGE_BACKEND="local"):
                created = client.post(
                    profile_image_url(self.emp_a1.id),
                    {"file": png_file("avatar.png")},
                    format="multipart",
                )
                self.assertEqual(created.status_code, 200, created.content)
                self.assertEqual(created.json()["data"]["profile_image"], "")
                self.emp_a1.refresh_from_db()
                self.assertTrue(self.emp_a1.profile_image.startswith("companies/"))
                self.assertIn("/profile/", self.emp_a1.profile_image)
                first_key = self.emp_a1.profile_image
                self.assertTrue(
                    AuditLog.objects.filter(
                        action=AuditAction.PROFILE_IMAGE_UPDATED,
                        entity_id=str(self.emp_a1.id),
                    ).exists()
                )
                fetched = client.get(profile_image_url(self.emp_a1.id))
                self.assertEqual(fetched.status_code, 200)
                self.assertTrue(read_download(fetched).startswith(b"\x89PNG"))
                replaced = client.post(
                    profile_image_url(self.emp_a1.id),
                    {"file": jpeg_file("face.jpg")},
                    format="multipart",
                )
                self.assertEqual(replaced.status_code, 200)
                self.emp_a1.refresh_from_db()
                self.assertNotEqual(self.emp_a1.profile_image, first_key)
                cleared = client.delete(profile_image_url(self.emp_a1.id))
                self.assertEqual(cleared.status_code, 200)
                self.emp_a1.refresh_from_db()
                self.assertEqual(self.emp_a1.profile_image, "")

    def test_rejects_pdf_and_cross_company(self) -> None:
        client = self.authenticate(self.admin_a)
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media):
                bad = client.post(
                    profile_image_url(self.emp_a1.id),
                    {"file": pdf_file("not-an-image.pdf")},
                    format="multipart",
                )
                self.assertEqual(bad.status_code, 400)
                other = client.post(
                    profile_image_url(self.emp_b1.id),
                    {"file": png_file()},
                    format="multipart",
                )
                self.assertEqual(other.status_code, 404)

    def test_employee_can_update_own_photo_not_a_peer(self) -> None:
        client = self.authenticate(self.employee_a)
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media):
                own = client.post(
                    profile_image_url(self.emp_a1.id),
                    {"file": png_file("me.png")},
                    format="multipart",
                )
                self.assertEqual(own.status_code, 200, own.content)
                peer = client.post(
                    profile_image_url(self.emp_a2.id),
                    {"file": png_file("peer.png")},
                    format="multipart",
                )
                self.assertEqual(peer.status_code, 404)

    def test_list_does_not_expose_object_key(self) -> None:
        self.emp_a1.profile_image = (
            f"companies/{self.company_a.id}/employees/{self.emp_a1.id}/profile/x.png"
        )
        self.emp_a1.save(update_fields=["profile_image"])
        client = self.authenticate(self.admin_a)
        detail = client.get(f"{EMPLOYEES}/{self.emp_a1.id}/")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["data"]["profile_image"], "")

    def test_employee_patch_without_profile_image_keeps_private_key(self) -> None:
        key = (
            f"companies/{self.company_a.id}/employees/{self.emp_a1.id}/profile/x.png"
        )
        self.emp_a1.profile_image = key
        self.emp_a1.save(update_fields=["profile_image"])
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{EMPLOYEES}/{self.emp_a1.id}/",
            {"first_name": "Ada"},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.content)
        self.emp_a1.refresh_from_db()
        self.assertEqual(self.emp_a1.profile_image, key)
        self.assertEqual(response.json()["data"]["profile_image"], "")

    def test_employee_patch_empty_profile_image_clears_private_key(self) -> None:
        key = (
            f"companies/{self.company_a.id}/employees/{self.emp_a1.id}/profile/x.png"
        )
        self.emp_a1.profile_image = key
        self.emp_a1.save(update_fields=["profile_image"])
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{EMPLOYEES}/{self.emp_a1.id}/",
            {"profile_image": ""},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.content)
        self.emp_a1.refresh_from_db()
        self.assertEqual(self.emp_a1.profile_image, "")

    def test_mismatched_image_content_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        with TemporaryDirectory() as media:
            with override_settings(MEDIA_ROOT=media):
                spoofed = client.post(
                    profile_image_url(self.emp_a1.id),
                    {
                        "file": uploaded(
                            "face.png", b"%PDF-1.4", "image/png"
                        )
                    },
                    format="multipart",
                )
        self.assertEqual(spoofed.status_code, 400)
