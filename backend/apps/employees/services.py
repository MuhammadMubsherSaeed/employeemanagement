"""Employee writes stay in serializers + tenant mixins.

Audit logs are written in the same database transaction as the employee row.
"""

from django.db import transaction

from apps.audit_logs.constants import AuditAction, AuditEntityType
from apps.audit_logs.services import AuditService, changed_fields
from apps.employees.models import EmployeeStatus


def employee_snapshot(employee) -> dict:
    department = getattr(employee, "department", None)
    position = getattr(employee, "position", None)
    return {
        "employee_code": employee.employee_code,
        "first_name": employee.first_name,
        "last_name": employee.last_name,
        "status": employee.status,
        "department_id": str(employee.department_id) if employee.department_id else None,
        "department": department.name if department is not None else None,
        "position_id": str(employee.position_id) if employee.position_id else None,
        "position": position.title if position is not None else None,
        "manager_id": str(employee.manager_id) if employee.manager_id else None,
        "employment_type": employee.employment_type,
        "joining_date": (
            employee.joining_date.isoformat() if employee.joining_date else None
        ),
        "user_id": employee.user_id,
    }


def department_snapshot(department) -> dict:
    return {
        "name": department.name,
        "description": department.description,
        "status": department.status,
        "manager_id": str(department.manager_id) if department.manager_id else None,
    }


def _actor(request):
    if request is None:
        return None
    user = getattr(request, "user", None)
    return user if getattr(user, "is_authenticated", False) else None


def record_employee_created(*, employee, request) -> None:
    AuditService.log(
        company=employee.company,
        user=_actor(request),
        action=AuditAction.EMPLOYEE_CREATED,
        entity_type=AuditEntityType.EMPLOYEE,
        entity_id=employee.id,
        new_value=employee_snapshot(employee),
        request=request,
    )


def record_employee_updated(*, previous: dict, employee, request) -> None:
    current = employee_snapshot(employee)
    old_value, new_value = changed_fields(previous, current)
    if not old_value and not new_value:
        return
    deactivated = previous.get("status") not in {
        EmployeeStatus.INACTIVE,
        EmployeeStatus.TERMINATED,
    } and employee.status in {EmployeeStatus.INACTIVE, EmployeeStatus.TERMINATED}
    AuditService.log(
        company=employee.company,
        user=_actor(request),
        action=(
            AuditAction.EMPLOYEE_DEACTIVATED
            if deactivated
            else AuditAction.EMPLOYEE_UPDATED
        ),
        entity_type=AuditEntityType.EMPLOYEE,
        entity_id=employee.id,
        old_value=old_value,
        new_value=new_value,
        request=request,
    )


def record_department_created(*, department, request) -> None:
    AuditService.log(
        company=department.company,
        user=_actor(request),
        action=AuditAction.DEPARTMENT_CREATED,
        entity_type=AuditEntityType.DEPARTMENT,
        entity_id=department.id,
        new_value=department_snapshot(department),
        request=request,
    )


def record_department_updated(*, previous: dict, department, request) -> None:
    current = department_snapshot(department)
    old_value, new_value = changed_fields(previous, current)
    if not old_value and not new_value:
        return
    AuditService.log(
        company=department.company,
        user=_actor(request),
        action=AuditAction.DEPARTMENT_UPDATED,
        entity_type=AuditEntityType.DEPARTMENT,
        entity_id=department.id,
        old_value=old_value,
        new_value=new_value,
        request=request,
    )


class EmployeeService:
    """Trusted server-side employee writes that also emit audit logs."""

    @transaction.atomic
    def create(self, *, serializer, extras: dict):
        request = serializer.context.get("request")
        employee = serializer.save(**extras)
        record_employee_created(employee=employee, request=request)
        return employee
