from unittest.mock import patch

from django.core.files.base import ContentFile
from django.test import TestCase, override_settings

from apps.common.storage import (
    PrivateFileSystemStorage,
    StorageDeleteError,
    StorageService,
    get_object_storage,
)


class StorageServiceTests(TestCase):
    @override_settings(STORAGE_BACKEND="local")
    def test_signed_url_is_none_for_local_backend(self) -> None:
        self.assertIsNone(StorageService().signed_url("companies/a/file.pdf"))

    @override_settings(STORAGE_BACKEND="s3", AWS_QUERYSTRING_EXPIRE=120)
    def test_signed_url_uses_storage_url_for_s3(self) -> None:
        with patch("apps.common.storage.default_storage") as storage:
            storage.url.return_value = "https://bucket.example/key?X-Amz-Signature=abc"
            url = StorageService().signed_url("companies/a/file.pdf")
        self.assertTrue(url.startswith("https://"))
        self.assertIn("Signature", url)

    def test_delete_missing_is_ok_by_default(self) -> None:
        with patch("apps.common.storage.default_storage") as storage:
            storage.exists.return_value = False
            StorageService().delete("missing-key")
            storage.delete.assert_not_called()

    def test_delete_raises_when_existing_object_cannot_be_removed(self) -> None:
        with patch("apps.common.storage.default_storage") as storage:
            storage.exists.return_value = True
            storage.delete.side_effect = OSError("denied")
            with self.assertRaises(StorageDeleteError):
                StorageService().delete("companies/a/file.pdf")

    def test_factory_returns_storage_service(self) -> None:
        self.assertIsInstance(get_object_storage(), StorageService)

    def test_local_storage_keeps_posix_object_keys(self) -> None:
        key = (
            "companies/11111111-1111-1111-1111-111111111111/"
            "employees/22222222-2222-2222-2222-222222222222/"
            "documents/33333333-3333-3333-3333-333333333333/"
            "abcdef0123456789abcdef0123456789.pdf"
        )
        storage = PrivateFileSystemStorage()
        generated = storage.generate_filename(key)
        self.assertEqual(generated, key)
        self.assertNotIn("\\", generated)
        saved = storage.save(key, ContentFile(b"%PDF-1.4 test"))
        self.assertEqual(saved, key)
        self.assertTrue(storage.exists(key))
        storage.delete(key)
