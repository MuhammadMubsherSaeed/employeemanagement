# Employee Documents Management

Company-scoped employee document upload, metadata, and authorized download in `apps.documents`. Files are stored through Django’s configured storage (`FileField`); PostgreSQL holds only metadata. Tenant is taken from `CompanyMembership`, never from the client.

Python 3.12 · Django 5.2 · DRF. App label: `documents` (`apps.documents`).

---

## 1. Model

`EmployeeDocument`

| Field | Notes |
| --- | --- |
| `id` | UUID |
| `company` | FK `Company`. Set from tenant context / employee, never from the client |
| `employee` | FK `Employee`. Must belong to the same company |
| `document_type` | Controlled `DocumentType` |
| `title` | Required, trimmed |
| `description` | Optional |
| `file` | `FileField`; storage path is generated, not the raw upload name |
| `file_name` | Sanitized original name (display only) |
| `file_size` | Bytes, server-derived |
| `mime_type` | Server-derived from sniffed content |
| `status` | `ACTIVE` (default), `EXPIRED`, `ARCHIVED` |
| `expiry_date` | Optional. Documents may have no expiry |
| `uploaded_by` | FK `User`, set from the authenticated actor |
| `created_at`, `updated_at` | From `TimeStampedModel` |

---

## 2. Document types

`CNIC`, `PASSPORT`, `CONTRACT`, `OFFER_LETTER`, `RESUME`, `EDUCATION_CERTIFICATE`, `EXPERIENCE_LETTER`, `BANK_DOCUMENT`, `TAX_DOCUMENT`, `MEDICAL_DOCUMENT`, `IDENTITY_DOCUMENT`, `OTHER`.

Types are not globally configurable in this module.

---

## 3. Status

`ACTIVE`, `EXPIRED`, `ARCHIVED`.

The API does **not** auto-mark a row `EXPIRED` from `expiry_date`. `EXPIRED` is only allowed when `expiry_date` is set and is in the past. Frontend date math cannot bypass that rule.

---

## 4. Upload

`POST /api/v1/documents/` (multipart)

Body: `employee_id`, `document_type`, `title`, optional `description`, `file`, optional `expiry_date`.

Ignored or stripped: `company_id`, `uploaded_by`, `file_size`, `mime_type`. Status is always `ACTIVE` on create.

---

## 5. File validation

Configurable:

- `MAX_DOCUMENT_UPLOAD_SIZE` (default 10 MiB)
- `DOCUMENT_ALLOWED_EXTENSIONS` (`pdf`, `doc`, `docx`, `jpg`, `jpeg`, `png`)
- `DOCUMENT_EXPIRING_SOON_DAYS` (default 30; list filter only)

Validation uses the extension **and** content sniff (PDF header, JPEG/PNG magic, OLE `.doc`, ZIP+`word/` / `[Content_Types].xml` for `.docx`). Executables and mismatched content are rejected. Oversized or unsupported files return **400** (`VALIDATION_ERROR`), consistent with leave attachments.

---

## 6. Storage

`upload_to`: `documents/{company_id}/{employee_id}/{uuid}{ext}`.

Filenames are sanitized (`sanitize_file_name`); path traversal segments are dropped. Serializers never return the storage path or a public `/media/` URL. Downloads go through the authorized endpoint.

---

## 7. Download

`GET /api/v1/documents/{id}/download/`

Authenticates, resolves the tenant, confirms the document is in authorization scope, then returns `FileResponse` (`as_attachment`, sanitized `file_name`). Missing storage or out-of-scope IDs return **404**. Requires `documents.download`.

---

## 8. List, detail, update, delete

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/api/v1/documents/` | `documents.view` |
| POST | `/api/v1/documents/` | `documents.create` |
| GET | `/api/v1/documents/{id}/` | `documents.view` |
| PUT, PATCH | `/api/v1/documents/{id}/` | `documents.update` |
| DELETE | `/api/v1/documents/{id}/` | `documents.delete` |
| GET | `/api/v1/documents/{id}/download/` | `documents.download` |

Update may change `title`, `description`, `document_type`, `expiry_date`, `status`, and optionally replace `file`. Company, `uploaded_by`, and `created_at` are not writable. Replacement writes the new file first; the previous storage object is deleted on commit.

Delete removes the row and the stored file inside a transaction, then writes `document.deleted`.

---

## 9. Search, filtering, pagination

Search: `title`, `file_name`, `document_type`, employee first/last name, employee code.

Filters: `status`, `document_type`, `employee` (ignored for `EMPLOYEE` role), `expired`, `expiring_soon`, `expiry_date_from`, `expiry_date_to`.

Ordering: `created_at`, `title`, `document_type`, `status`, `expiry_date`, `file_name` (default `-created_at`).

Pagination: `StandardPagination` (`page`, `page_size` ≤ 100). Envelope: `{success, message, data: {count, next, previous, results}}`.

---

## 10. Permissions

| Code | Typical use |
| --- | --- |
| `documents.view` | List/retrieve metadata in scope |
| `documents.create` | Upload |
| `documents.update` | Metadata and file replacement |
| `documents.delete` | Delete row and file |
| `documents.download` | Protected download |

Default `EMPLOYEE`: view, create, download (own documents only). Default `MANAGER`: view, create, update, download (self + direct reports; **not** delete). Default `COMPANY_ADMIN`: all document codes, company-wide.

---

## 11. Manager authorization

Same direct-report rule as employees/leave: `Employee.manager`. Managers see and may upload/update documents for themselves and employees they manage. They do not see HR / other-team documents. Unauthorized employee or document IDs return **404**.

---

## 12. Employee authorization

Employees see only their own documents. They may upload for themselves when they have `documents.create`. They cannot update or delete (no `documents.update` / `documents.delete`). They cannot upload, view, or download another employee’s documents.

---

## 13. Tenant isolation

Querysets use `TenantAwareQuerySetMixin` / `ObjectAuthorization`. Cross-company IDs return **404**, not 403. `company_id` from query, body, or URL is ignored.

---

## 14. Audit

`apps.common.events.emit` → `AuditEvent`:

`document.uploaded`, `document.updated`, `document.replaced`, `document.archived`, `document.downloaded`, `document.deleted`.

---

## 15. Known limitations

- No OCR, e-sign, approval workflow, sharing links, version history, or expiry notifications.
- Status is not auto-expired from `expiry_date`.
- Development `DEBUG` still mounts Django `MEDIA_URL`; document serializers do not expose those paths. Use the download endpoint.
- Oversized / unsupported types are **400**, not 413/415.
- Django Admin is for platform operators and is not tenant-scoped.

After adding the app to an existing database, run migrations and `python manage.py seed_rbac` so document permission codes exist.

---

## API

Base: `/api/v1/documents/`

Envelope: existing `success` / `message` / `data` and error `code` / `errors`. OpenAPI: `/api/schema/`, `/api/docs/` (tag **Documents**).

Unauthenticated: 401. Missing permission: 403. Out of tenant or team scope: 404. Business/validation: 400.
