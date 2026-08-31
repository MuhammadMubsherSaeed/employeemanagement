from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context
from apps.documents.models import EmployeeDocument


def document_queryset():
    return EmployeeDocument.objects.select_related(
        "company",
        "employee",
        "employee__user",
        "employee__manager",
        "uploaded_by",
    )


def get_visible_documents(*, request):
    ctx = get_tenant_context(request)
    return ObjectAuthorization().filter_queryset(document_queryset(), ctx)


def get_employee_documents(*, request, employee):
    return get_visible_documents(request=request).filter(employee=employee)
