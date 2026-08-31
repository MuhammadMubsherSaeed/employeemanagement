import zipfile
from datetime import date, timedelta
from io import BytesIO
from tempfile import TemporaryDirectory

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings

from apps.documents.models import DocumentType, EmployeeDocument
from apps.employees.tests.fixtures import EmployeeFixtureMixin

DOCUMENTS = "/api/v1/documents"
DOCX_MIME = (
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
)


def pdf_bytes() -> bytes:
    return b"%PDF-1.4 test document"

def png_bytes() -> bytes:
    return b"\x89PNG\r\n\x1a\n" + b"\x00" * 24

def jpeg_bytes() -> bytes:
    return b"\xff\xd8\xff\xe0\x00\x10JFIF\x00" + b"\xff\xd9"

def doc_bytes() -> bytes:
    return b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1" + b"\x00" * 64

def docx_bytes() -> bytes:
    buffer = BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        archive.writestr(
            "[Content_Types].xml",
            '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"></Types>',
        )
        archive.writestr("word/document.xml", "<w:document/>")
    return buffer.getvalue()


def uploaded(name: str, content: bytes, content_type: str) -> SimpleUploadedFile:
    return SimpleUploadedFile(name, content, content_type=content_type)


def pdf_file(name: str = "cnic.pdf") -> SimpleUploadedFile:
    return uploaded(name, pdf_bytes(), "application/pdf")


def png_file(name: str = "photo.png") -> SimpleUploadedFile:
    return uploaded(name, png_bytes(), "image/png")


def jpeg_file(name: str = "photo.jpg") -> SimpleUploadedFile:
    return uploaded(name, jpeg_bytes(), "image/jpeg")


def jpeg_alt_file() -> SimpleUploadedFile:
    return uploaded("scan.jpeg", jpeg_bytes(), "image/jpeg")


def doc_file(name: str = "letter.doc") -> SimpleUploadedFile:
    return uploaded(name, doc_bytes(), "application/msword")


def docx_file(name: str = "resume.docx") -> SimpleUploadedFile:
    return uploaded(name, docx_bytes(), DOCX_MIME)


def read_download(response) -> bytes:
    if getattr(response, "streaming", False):
        return b"".join(response.streaming_content)
    return response.content


class DocumentFixtureMixin(EmployeeFixtureMixin):
    def setUp(self) -> None:
        super().setUp()
        self._media = TemporaryDirectory(ignore_cleanup_errors=True)
        self.addCleanup(self._media.cleanup)
        settings = override_settings(MEDIA_ROOT=self._media.name)
        settings.enable()
        self.addCleanup(settings.disable)

    def make_document(self, employee, **kwargs) -> EmployeeDocument:
        upload = kwargs.pop("file", None) or pdf_file()
        defaults = {
            "company": employee.company,
            "employee": employee,
            "document_type": DocumentType.CNIC,
            "title": "National ID",
            "description": "",
            "uploaded_by": employee.user,
            "file": upload,
        }
        defaults.update(kwargs)
        return EmployeeDocument.objects.create(**defaults)

    def upload(self, client, employee, **extra):
        body = {
            "employee_id": str(employee.id),
            "document_type": extra.pop("document_type", DocumentType.CNIC),
            "title": extra.pop("title", "National ID"),
            "file": extra.pop("file", pdf_file()),
        }
        if "description" in extra:
            body["description"] = extra.pop("description")
        if "expiry_date" in extra:
            body["expiry_date"] = extra.pop("expiry_date")
        body.update(extra)
        return client.post(f"{DOCUMENTS}/", body, format="multipart")

    def yesterday(self) -> str:
        return (date.today() - timedelta(days=1)).isoformat()

    def next_week(self) -> str:
        return (date.today() + timedelta(days=7)).isoformat()
