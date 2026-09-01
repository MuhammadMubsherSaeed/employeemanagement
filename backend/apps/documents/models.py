import re
import uuid
import zipfile
from io import BytesIO
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import FileExtensionValidator
from django.db import models
from django.utils import timezone

from apps.common.models import TimeStampedModel
from apps.common.storage import STORAGE_OBJECT_KEY_MAX_LENGTH
from apps.companies.models import Company
from apps.employees.models import Employee

MAX_TITLE_LENGTH = 255
MAX_DESCRIPTION_LENGTH = 2000
MAX_FILE_NAME_LENGTH = 255
MAX_MIME_LENGTH = 128

DEFAULT_ALLOWED_EXTENSIONS = (
    "pdf",
    "doc",
    "docx",
    "xls",
    "xlsx",
    "jpg",
    "jpeg",
    "png",
)
BLOCKED_EXTENSIONS = frozenset(
    {
        ".exe",
        ".bat",
        ".cmd",
        ".com",
        ".msi",
        ".js",
        ".sh",
        ".ps1",
        ".dll",
        ".scr",
        ".vbs",
    }
)

_UNSAFE_NAME = re.compile(r"[^A-Za-z0-9._-]+")

PDF_MIME = "application/pdf"
DOC_MIME = "application/msword"
DOCX_MIME = (
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
)
XLS_MIME = "application/vnd.ms-excel"
XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
JPEG_MIME = "image/jpeg"
PNG_MIME = "image/png"
WEBP_MIME = "image/webp"

MIME_BY_KIND = {
    "pdf": PDF_MIME,
    "doc": DOC_MIME,
    "docx": DOCX_MIME,
    "xls": XLS_MIME,
    "xlsx": XLSX_MIME,
    "jpg": JPEG_MIME,
    "jpeg": JPEG_MIME,
    "png": PNG_MIME,
    "webp": WEBP_MIME,
}


class DocumentType(models.TextChoices):
    CNIC = "CNIC", "CNIC"
    PASSPORT = "PASSPORT", "Passport"
    CONTRACT = "CONTRACT", "Contract"
    OFFER_LETTER = "OFFER_LETTER", "Offer letter"
    RESUME = "RESUME", "Resume"
    EDUCATION_CERTIFICATE = "EDUCATION_CERTIFICATE", "Education certificate"
    EDUCATION = "EDUCATION", "Education"
    EXPERIENCE_LETTER = "EXPERIENCE_LETTER", "Experience letter"
    EXPERIENCE = "EXPERIENCE", "Experience"
    CERTIFICATE = "CERTIFICATE", "Certificate"
    SALARY_DOCUMENT = "SALARY_DOCUMENT", "Salary document"
    BANK_DOCUMENT = "BANK_DOCUMENT", "Bank document"
    TAX_DOCUMENT = "TAX_DOCUMENT", "Tax document"
    MEDICAL_DOCUMENT = "MEDICAL_DOCUMENT", "Medical document"
    IDENTITY_DOCUMENT = "IDENTITY_DOCUMENT", "Identity document"
    OTHER = "OTHER", "Other"


class DocumentStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    EXPIRED = "EXPIRED", "Expired"
    ARCHIVED = "ARCHIVED", "Archived"


STATUS_TRANSITIONS = {
    DocumentStatus.ACTIVE: frozenset(
        {DocumentStatus.ARCHIVED, DocumentStatus.EXPIRED, DocumentStatus.ACTIVE}
    ),
    DocumentStatus.EXPIRED: frozenset(
        {DocumentStatus.ARCHIVED, DocumentStatus.ACTIVE, DocumentStatus.EXPIRED}
    ),
    DocumentStatus.ARCHIVED: frozenset(
        {DocumentStatus.ACTIVE, DocumentStatus.EXPIRED, DocumentStatus.ARCHIVED}
    ),
}


def allowed_document_extensions() -> tuple[str, ...]:
    configured = getattr(settings, "DOCUMENT_ALLOWED_EXTENSIONS", None)
    if configured:
        return tuple(str(item).lower().lstrip(".") for item in configured)
    return DEFAULT_ALLOWED_EXTENSIONS


def max_document_upload_bytes() -> int:
    return int(
        getattr(
            settings,
            "MAX_DOCUMENT_UPLOAD_SIZE",
            getattr(settings, "DOCUMENT_MAX_UPLOAD_BYTES", 10 * 1024 * 1024),
        )
    )


def expiring_soon_days() -> int:
    return int(getattr(settings, "DOCUMENT_EXPIRING_SOON_DAYS", 30))


def sanitize_file_name(filename: str) -> str:
    raw = Path(str(filename or "").replace("\\", "/")).name
    raw = raw.strip().lstrip(".")
    stem = Path(raw).stem
    suffix = Path(raw).suffix.lower()
    cleaned = _UNSAFE_NAME.sub("_", stem).strip("._") or "document"
    cleaned = cleaned[: MAX_FILE_NAME_LENGTH - len(suffix) - 1]
    return f"{cleaned}{suffix}"[:MAX_FILE_NAME_LENGTH]


def document_upload_path(instance, filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    if suffix not in {f".{ext}" for ext in allowed_document_extensions()}:
        suffix = ""
    company_id = instance.company_id or "unknown"
    employee_id = instance.employee_id or "unknown"
    document_id = instance.pk or uuid.uuid4()
    return (
        f"companies/{company_id}/employees/{employee_id}/documents/"
        f"{document_id}/{uuid.uuid4().hex}{suffix}"
    )


def profile_image_upload_path(employee, filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    allowed = {".jpg", ".jpeg", ".png", ".webp"}
    if suffix not in allowed:
        suffix = ""
    company_id = getattr(employee, "company_id", None) or "unknown"
    employee_id = getattr(employee, "pk", None) or "unknown"
    return (
        f"companies/{company_id}/employees/{employee_id}/profile/"
        f"{uuid.uuid4().hex}{suffix}"
    )


def leave_attachment_object_path(instance, filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    company_id = instance.company_id or "unknown"
    employee_id = instance.employee_id or "unknown"
    leave_id = instance.pk or uuid.uuid4()
    return (
        f"companies/{company_id}/employees/{employee_id}/leave/"
        f"{leave_id}/{uuid.uuid4().hex}{suffix}"
    )


def _read_prefix(file, size: int) -> bytes:
    if not hasattr(file, "read"):
        raise ValidationError("Upload a file.")
    position = file.tell() if hasattr(file, "tell") else 0
    try:
        if hasattr(file, "seek"):
            file.seek(0)
        return file.read(size) or b""
    finally:
        if hasattr(file, "seek"):
            try:
                file.seek(position)
            except Exception:
                file.seek(0)


def _kind_from_file(file) -> str | None:
    header = _read_prefix(file, 16)
    if header.startswith(b"%PDF"):
        return "pdf"
    if header.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if header.startswith(b"\xff\xd8\xff"):
        return "jpeg"
    if len(header) >= 12 and header.startswith(b"RIFF") and header[8:12] == b"WEBP":
        return "webp"
    if header.startswith(b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1"):
        suffix = Path(getattr(file, "name", "") or "").suffix.lower()
        if suffix == ".xls":
            return "xls"
        return "doc"
    if header.startswith(b"PK"):
        position = file.tell() if hasattr(file, "tell") else 0
        try:
            if hasattr(file, "seek"):
                file.seek(0)
            payload = file.read()
        finally:
            if hasattr(file, "seek"):
                try:
                    file.seek(position)
                except Exception:
                    file.seek(0)
        try:
            names = {
                name.replace("\\", "/").lower()
                for name in zipfile.ZipFile(BytesIO(payload)).namelist()
            }
        except zipfile.BadZipFile:
            return None
        if any(name.startswith("xl/") for name in names):
            return "xlsx"
        if any(name.startswith("word/") for name in names):
            return "docx"
    return None


def sniff_document_kind(file) -> str:
    size = getattr(file, "size", None)
    if size == 0:
        raise ValidationError("Upload a file.")
    kind = _kind_from_file(file)
    if kind is None:
        raise ValidationError("This file type is not allowed.")
    return kind


def is_committed_storage_file(file) -> bool:
    """True when Django already stored this FieldFile; do not re-open it."""
    return bool(getattr(file, "_committed", False))


def validate_employee_document_file(file) -> None:
    if is_committed_storage_file(file):
        return
    name = getattr(file, "name", "") or ""
    suffix = Path(name).suffix.lower()
    if suffix in BLOCKED_EXTENSIONS:
        raise ValidationError("This file type is not allowed.")
    allowed = {f".{ext}" for ext in allowed_document_extensions()}
    if suffix not in allowed:
        raise ValidationError(
            "Document must be a PDF, Word document, Excel spreadsheet, JPEG, or PNG."
        )
    size = getattr(file, "size", None)
    if size is None:
        raise ValidationError("Upload a file.")
    if size <= 0:
        raise ValidationError("Upload a file.")
    limit = max_document_upload_bytes()
    if size > limit:
        raise ValidationError("This file is too large.")
    kind = sniff_document_kind(file)
    expected = {
        ".pdf": {"pdf"},
        ".doc": {"doc"},
        ".docx": {"docx"},
        ".xls": {"xls"},
        ".xlsx": {"xlsx"},
        ".jpg": {"jpeg"},
        ".jpeg": {"jpeg"},
        ".png": {"png"},
    }
    if kind not in expected.get(suffix, set()):
        raise ValidationError("File content does not match the file extension.")


PROFILE_IMAGE_EXTENSIONS = ("jpg", "jpeg", "png", "webp")
LEAVE_SNIFF_EXTENSIONS = {
    ".pdf": {"pdf"},
    ".png": {"png"},
    ".jpg": {"jpeg"},
    ".jpeg": {"jpeg"},
    ".webp": {"webp"},
    ".doc": {"doc"},
    ".docx": {"docx"},
}


def max_profile_image_bytes() -> int:
    return int(getattr(settings, "MAX_PROFILE_IMAGE_UPLOAD_SIZE", 2 * 1024 * 1024))


def validate_profile_image_file(file) -> None:
    if is_committed_storage_file(file):
        return
    name = getattr(file, "name", "") or ""
    suffix = Path(name).suffix.lower()
    if suffix in BLOCKED_EXTENSIONS:
        raise ValidationError("This file type is not allowed.")
    allowed = {f".{ext}" for ext in PROFILE_IMAGE_EXTENSIONS}
    if suffix not in allowed:
        raise ValidationError("Profile image must be a JPEG, PNG, or WebP.")
    size = getattr(file, "size", None)
    if size is None or size <= 0:
        raise ValidationError("Upload a file.")
    if size > max_profile_image_bytes():
        raise ValidationError("This file is too large.")
    kind = sniff_document_kind(file)
    expected = {
        ".jpg": {"jpeg"},
        ".jpeg": {"jpeg"},
        ".png": {"png"},
        ".webp": {"webp"},
    }
    if kind not in expected.get(suffix, set()):
        raise ValidationError("File content does not match the file extension.")


def is_http_url(value: str) -> bool:
    text = (value or "").strip()
    return text.startswith("http://") or text.startswith("https://")


def detected_mime_type(file) -> str:
    kind = sniff_document_kind(file)
    if kind == "jpeg":
        return JPEG_MIME
    return MIME_BY_KIND[kind]


class EmployeeDocument(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="employee_documents",
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name="documents",
    )
    document_type = models.CharField(
        max_length=32,
        choices=DocumentType.choices,
        db_index=True,
    )
    title = models.CharField(max_length=MAX_TITLE_LENGTH)
    description = models.TextField(max_length=MAX_DESCRIPTION_LENGTH, blank=True)
    file = models.FileField(
        upload_to=document_upload_path,
        max_length=STORAGE_OBJECT_KEY_MAX_LENGTH,
        validators=[
            FileExtensionValidator(DEFAULT_ALLOWED_EXTENSIONS),
            validate_employee_document_file,
        ],
    )
    file_name = models.CharField(max_length=MAX_FILE_NAME_LENGTH)
    file_size = models.PositiveBigIntegerField()
    mime_type = models.CharField(max_length=MAX_MIME_LENGTH)
    status = models.CharField(
        max_length=16,
        choices=DocumentStatus.choices,
        default=DocumentStatus.ACTIVE,
        db_index=True,
    )
    expiry_date = models.DateField(null=True, blank=True, db_index=True)
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="uploaded_documents",
        null=True,
        blank=True,
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=("company",)),
            models.Index(fields=("employee",)),
            models.Index(fields=("document_type",)),
            models.Index(fields=("status",)),
            models.Index(fields=("expiry_date",)),
            models.Index(fields=("company", "employee")),
            models.Index(fields=("company", "document_type")),
            models.Index(fields=("company", "status")),
        ]

    def __str__(self) -> str:
        return f"{self.title} ({self.employee})"

    def normalize(self) -> None:
        self.title = (self.title or "").strip()
        self.description = (self.description or "").strip()
        self.file_name = sanitize_file_name(
            self.file_name or getattr(self.file, "name", "")
        )
        self.mime_type = (self.mime_type or "").strip()[:MAX_MIME_LENGTH]

    def clean(self) -> None:
        self.normalize()
        errors: dict[str, str] = {}
        if len(self.title) < 2:
            errors["title"] = "Enter a document title."
        if self.employee_id and self.company_id:
            if self.employee.company_id != self.company_id:
                errors["employee"] = "Employee must belong to the same company."
        if self.status == DocumentStatus.EXPIRED:
            today = timezone.localdate()
            if self.expiry_date is None or self.expiry_date >= today:
                errors["status"] = (
                    "EXPIRED is only allowed when expiry_date is in the past."
                )
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        if self.company_id is None and self.employee_id:
            self.company_id = self.employee.company_id
        if self.file and not self.file_name:
            self.file_name = sanitize_file_name(getattr(self.file, "name", "document"))
        if self.file and not self.file_size:
            self.file_size = int(getattr(self.file, "size", 0) or 0)
        if self.file and not self.mime_type:
            self.mime_type = detected_mime_type(self.file)
        self.full_clean()
        result = super().save(*args, **kwargs)
        if self.file:
            try:
                self.file.close()
            except Exception:
                pass
        return result
