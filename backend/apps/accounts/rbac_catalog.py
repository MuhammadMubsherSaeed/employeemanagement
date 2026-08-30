"""Stable RBAC codes. Authorization must use these strings, never numeric IDs."""

from apps.accounts.models import UserRole

ROLE_SCOPE_PLATFORM = "PLATFORM"
ROLE_SCOPE_COMPANY = "COMPANY"

PERMISSION_CODES = (
    "employees.view",
    "employees.create",
    "employees.update",
    "employees.delete",
    "attendance.view",
    "attendance.manage",
    "attendance.check_in",
    "attendance.check_out",
    "leave.view",
    "leave.create",
    "leave.approve",
    "leave.reject",
    "leave.manage",
    "devices.view",
    "devices.create",
    "devices.update",
    "devices.assign",
    "devices.return",
    "reports.view",
    "reports.export",
    "settings.manage",
    "audit_logs.view",
)

PERMISSION_META = {
    "employees.view": ("View employees", "employees"),
    "employees.create": ("Create employees", "employees"),
    "employees.update": ("Update employees", "employees"),
    "employees.delete": ("Delete employees", "employees"),
    "attendance.view": ("View attendance", "attendance"),
    "attendance.manage": ("Manage attendance", "attendance"),
    "attendance.check_in": ("Check in", "attendance"),
    "attendance.check_out": ("Check out", "attendance"),
    "leave.view": ("View leave", "leave"),
    "leave.create": ("Create leave", "leave"),
    "leave.approve": ("Approve leave", "leave"),
    "leave.reject": ("Reject leave", "leave"),
    "leave.manage": ("Manage leave", "leave"),
    "devices.view": ("View devices", "devices"),
    "devices.create": ("Create devices", "devices"),
    "devices.update": ("Update devices", "devices"),
    "devices.assign": ("Assign devices", "devices"),
    "devices.return": ("Return devices", "devices"),
    "reports.view": ("View reports", "reports"),
    "reports.export": ("Export reports", "reports"),
    "settings.manage": ("Manage settings", "settings"),
    "audit_logs.view": ("View audit logs", "audit_logs"),
}

COMPANY_ADMIN_PERMISSIONS = PERMISSION_CODES

MANAGER_PERMISSIONS = (
    "employees.view",
    "employees.update",
    "attendance.view",
    "attendance.manage",
    "leave.view",
    "leave.approve",
    "leave.reject",
    "leave.manage",
    "devices.view",
    "reports.view",
)

EMPLOYEE_PERMISSIONS = (
    "employees.view",
    "attendance.view",
    "attendance.check_in",
    "attendance.check_out",
    "leave.view",
    "leave.create",
    "devices.view",
)

ROLE_DEFINITIONS = (
    {
        "code": UserRole.SUPER_ADMIN,
        "name": "Super Admin",
        "scope": ROLE_SCOPE_PLATFORM,
        "description": "Platform operator. Not bound to a company tenant.",
        "permissions": (),
    },
    {
        "code": UserRole.COMPANY_ADMIN,
        "name": "Company Admin",
        "scope": ROLE_SCOPE_COMPANY,
        "description": "Full access within a single company.",
        "permissions": COMPANY_ADMIN_PERMISSIONS,
    },
    {
        "code": UserRole.MANAGER,
        "name": "Manager",
        "scope": ROLE_SCOPE_COMPANY,
        "description": "Team operations within a company. No settings.manage.",
        "permissions": MANAGER_PERMISSIONS,
    },
    {
        "code": UserRole.EMPLOYEE,
        "name": "Employee",
        "scope": ROLE_SCOPE_COMPANY,
        "description": (
            "Self-service HR actions. "
            "Object-level rules further restrict data."
        ),
        "permissions": EMPLOYEE_PERMISSIONS,
    },
)
