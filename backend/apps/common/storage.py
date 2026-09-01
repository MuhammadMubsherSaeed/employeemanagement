"""S3-compatible object storage adapter.

Business modules must use this module instead of boto3 or provider SDKs.
``STORAGE_BACKEND=local`` (default) uses Django's file storage and never
returns a public or signed URL. ``STORAGE_BACKEND=s3`` uses django-storages
with private ACLs and short-lived query-string auth.
"""

from __future__ import annotations

import inspect
import pathlib
import posixpath
import time
from typing import IO, Any

from django.conf import settings
from django.core.exceptions import SuspiciousFileOperation
from django.core.files.storage import FileSystemStorage, default_storage
from django.core.files.utils import validate_file_name
from rest_framework.exceptions import APIException

# Tenant object keys include several UUIDs; Django's FileField default (100)
# is too short and Windows os.path.normpath would otherwise rewrite keys.
STORAGE_OBJECT_KEY_MAX_LENGTH = 512


def normalize_object_key(key: str) -> str:
    return str(key or "").replace("\\", "/")


class PrivateFileSystemStorage(FileSystemStorage):
    """Local storage that keeps POSIX object keys on every platform."""

    def generate_filename(self, filename):
        filename = normalize_object_key(filename)
        dirname, basename = posixpath.split(filename)
        if ".." in pathlib.PurePosixPath(dirname).parts:
            raise SuspiciousFileOperation(
                f"Detected path traversal attempt in '{dirname}'"
            )
        basename = self.get_valid_name(basename)
        if dirname:
            return posixpath.join(dirname, basename)
        return basename

    def get_available_name(self, name, max_length=None):
        name = normalize_object_key(name)
        dir_name, file_name = posixpath.split(name)
        if ".." in pathlib.PurePosixPath(dir_name).parts:
            raise SuspiciousFileOperation(
                f"Detected path traversal attempt in '{dir_name}'"
            )
        validate_file_name(file_name)
        file_ext = "".join(pathlib.PurePosixPath(file_name).suffixes)
        file_root = file_name.removesuffix(file_ext)
        while not self.is_name_available(name, max_length=max_length):
            name = posixpath.join(
                dir_name, self.get_alternative_name(file_root, file_ext)
            )
            if max_length is None:
                continue
            truncation = len(name) - max_length
            if truncation > 0:
                file_root = file_root[:-truncation]
                if not file_root:
                    raise SuspiciousFileOperation(
                        f'Storage can not find an available filename for "{name}". '
                        "Please make sure that the corresponding file field "
                        'allows sufficient "max_length".'
                    )
                name = posixpath.join(
                    dir_name, self.get_alternative_name(file_root, file_ext)
                )
        return name


class StorageError(Exception):
    """Object storage failed in a way the caller should surface."""


class StorageDeleteError(StorageError):
    """An existing object could not be deleted."""


class StorageUnavailable(APIException):
    status_code = 503
    default_code = "storage_error"
    default_detail = "File storage is unavailable."


class StorageService:
    """Provider-agnostic upload, delete, exists, metadata, and signed URLs."""

    def save(self, key: str, content: IO[Any] | Any) -> str:
        if not key:
            raise StorageError("A storage key is required.")
        try:
            stored = default_storage.save(normalize_object_key(key), content)
        except Exception as exc:
            raise StorageError("The file could not be stored.") from exc
        return normalize_object_key(stored)

    def delete(self, key: str, *, missing_ok: bool = True) -> None:
        key = normalize_object_key(key)
        if not key:
            return
        try:
            exists = default_storage.exists(key)
        except Exception as exc:
            raise StorageDeleteError("File storage is unavailable.") from exc
        if not exists:
            if missing_ok:
                return
            raise StorageDeleteError("Object is missing.")
        last_error: Exception | None = None
        for _attempt in range(5):
            try:
                default_storage.delete(key)
                last_error = None
                break
            except FileNotFoundError:
                if missing_ok:
                    return
                raise StorageDeleteError("Object is missing.") from None
            except OSError as exc:
                if getattr(exc, "winerror", None) not in (5, 32) and getattr(
                    exc, "errno", None
                ) != 13:
                    raise StorageDeleteError(
                        "The stored file could not be deleted."
                    ) from exc
                last_error = exc
                time.sleep(0.05)
            except Exception as exc:
                raise StorageDeleteError(
                    "The stored file could not be deleted."
                ) from exc
        if last_error is not None:
            raise StorageDeleteError(
                "The stored file could not be deleted."
            ) from last_error
        if default_storage.exists(key):
            raise StorageDeleteError("The stored file could not be deleted.")

    def exists(self, key: str) -> bool:
        key = normalize_object_key(key)
        if not key:
            return False
        try:
            return bool(default_storage.exists(key))
        except Exception as exc:
            raise StorageError("File storage is unavailable.") from exc

    def open(self, key: str, mode: str = "rb"):
        key = normalize_object_key(key)
        if not key:
            raise StorageError("A storage key is required.")
        try:
            return default_storage.open(key, mode)
        except (FileNotFoundError, OSError, ValueError) as exc:
            raise StorageError("File is not available.") from exc

    def read(self, key: str) -> bytes:
        handle = self.open(key)
        try:
            return handle.read()
        finally:
            closer = getattr(handle, "close", None)
            if callable(closer):
                closer()

    def metadata(self, key: str) -> dict[str, Any]:
        key = normalize_object_key(key)
        if not key or not self.exists(key):
            return {"key": key, "exists": False, "size": None}
        try:
            size = default_storage.size(key)
        except Exception:
            size = None
        return {"key": key, "exists": True, "size": size}

    def signed_url(
        self, key: str, *, expires_in: int | None = None
    ) -> str | None:
        """Return a short-lived URL for private S3 objects, else None.

        Local/FileSystem backends must not expose MEDIA_URL. Callers should
        stream through an authenticated API when this returns None.
        """
        key = normalize_object_key(key)
        if not key:
            return None
        if getattr(settings, "STORAGE_BACKEND", "local") != "s3":
            return None
        expire = expires_in
        if expire is None:
            expire = int(getattr(settings, "AWS_QUERYSTRING_EXPIRE", 300))
        url_method = getattr(default_storage, "url", None)
        if url_method is None:
            return None
        try:
            try:
                params = inspect.signature(url_method).parameters
            except (TypeError, ValueError):
                params = {}
            if "expire" in params:
                return url_method(key, expire=expire)
            return url_method(key)
        except Exception:
            return None


def get_object_storage() -> StorageService:
    return StorageService()
