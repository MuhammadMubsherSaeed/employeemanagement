from django.db import models


class AuditAction(models.TextChoices):
    EMPLOYEE_CREATED = "EMPLOYEE_CREATED", "Employee created"
    EMPLOYEE_UPDATED = "EMPLOYEE_UPDATED", "Employee updated"
    EMPLOYEE_DEACTIVATED = "EMPLOYEE_DEACTIVATED", "Employee deactivated"
    DEPARTMENT_CREATED = "DEPARTMENT_CREATED", "Department created"
    DEPARTMENT_UPDATED = "DEPARTMENT_UPDATED", "Department updated"
    LEAVE_SUBMITTED = "LEAVE_SUBMITTED", "Leave submitted"
    LEAVE_APPROVED = "LEAVE_APPROVED", "Leave approved"
    LEAVE_REJECTED = "LEAVE_REJECTED", "Leave rejected"
    LEAVE_CANCELLED = "LEAVE_CANCELLED", "Leave cancelled"
    DEVICE_ASSIGNED = "DEVICE_ASSIGNED", "Device assigned"
    DEVICE_RETURNED = "DEVICE_RETURNED", "Device returned"
    ROLE_CHANGED = "ROLE_CHANGED", "Role changed"
    PERMISSION_CHANGED = "PERMISSION_CHANGED", "Permission changed"
    SETTINGS_CHANGED = "SETTINGS_CHANGED", "Settings changed"


class AuditEntityType(models.TextChoices):
    EMPLOYEE = "EMPLOYEE", "Employee"
    DEPARTMENT = "DEPARTMENT", "Department"
    LEAVE_REQUEST = "LEAVE_REQUEST", "Leave request"
    DEVICE = "DEVICE", "Device"
    USER = "USER", "User"
    ROLE = "ROLE", "Role"
    COMPANY_SETTINGS = "COMPANY_SETTINGS", "Company settings"
