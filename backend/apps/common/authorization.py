from __future__ import annotations

from django.db.models import Q

from apps.accounts.models import UserRole
from apps.common.tenancy import TenantContext


class TeamScope:
    """Direct-report team membership via Employee.manager.

    A manager's team is: their own employee row plus employees whose
    manager FK points at that row. No department-wide or transitive
    hierarchy is implied.
    """

    def is_in_team(self, ctx: TenantContext, target_user_id: int) -> bool:
        if not target_user_id or ctx.company is None or ctx.user is None:
            return False
        from apps.employees.models import Employee

        my_id = (
            Employee.objects.filter(
                company_id=ctx.company.id, user_id=ctx.user.id
            )
            .values_list("id", flat=True)
            .first()
        )
        if my_id is None:
            return False
        return Employee.objects.filter(
            company_id=ctx.company.id,
            user_id=target_user_id,
            manager_id=my_id,
        ).exists()


class ObjectAuthorization:
    """Can this actor access this tenant-owned object?"""

    def __init__(self, team_scope: TeamScope | None = None) -> None:
        self.team_scope = team_scope or TeamScope()

    def belongs_to_tenant(self, ctx: TenantContext, obj) -> bool:
        company_id = getattr(obj, "company_id", None)
        if company_id is None:
            return False
        if ctx.is_super_admin:
            return True
        if ctx.company is None:
            return False
        return company_id == ctx.company.id

    def can_view(self, ctx: TenantContext, obj) -> bool:
        if self._is_notification(obj) or self._is_device_token(obj):
            return self._can_view_own_inbox_resource(ctx, obj)
        if not self.belongs_to_tenant(ctx, obj):
            return False
        if ctx.is_super_admin:
            return True
        if self._is_employee(obj):
            return self._can_view_employee(ctx, obj)
        if self._is_attendance(obj):
            return self._can_view_attendance(ctx, obj)
        if self._is_leave_type(obj):
            return True
        if self._is_leave_employee_owned(obj):
            employee = getattr(obj, "employee", None)
            return employee is not None and self._can_view_employee(ctx, employee)
        if self._is_document(obj):
            employee = getattr(obj, "employee", None)
            return employee is not None and self._can_view_employee(ctx, employee)
        if self._is_device(obj):
            return self._can_view_device(ctx, obj)
        if self._is_device_assignment(obj):
            device = getattr(obj, "device", None)
            return device is not None and self._can_view_device(ctx, device)
        visibility = getattr(obj, "visibility", "COMPANY")
        owner_id = getattr(obj, "owner_id", None)
        if visibility == "PRIVATE":
            return self._can_view_private(ctx, owner_id)
        return True

    def can_change(self, ctx: TenantContext, obj) -> bool:
        if not self.can_view(ctx, obj):
            return False
        if self._is_notification(obj) or self._is_device_token(obj):
            return True
        if ctx.is_super_admin or ctx.role_code == UserRole.COMPANY_ADMIN:
            return True
        if self._is_employee(obj):
            return self._can_change_employee(ctx, obj)
        if self._is_attendance(obj):
            return False
        if self._is_leave_type(obj):
            return ctx.role_code in (UserRole.COMPANY_ADMIN, UserRole.MANAGER)
        if self._is_leave_balance(obj):
            employee = getattr(obj, "employee", None)
            if employee is None:
                return False
            if ctx.role_code == UserRole.COMPANY_ADMIN:
                return True
            if ctx.role_code == UserRole.MANAGER:
                return self._can_view_employee(ctx, employee)
            return False
        if self._is_leave_request(obj):
            employee = getattr(obj, "employee", None)
            if employee is None:
                return False
            if ctx.role_code == UserRole.COMPANY_ADMIN:
                return True
            if employee.user_id == ctx.user.id:
                return True
            if ctx.role_code == UserRole.MANAGER:
                return self._is_direct_report(ctx, employee)
            return False
        if self._is_document(obj):
            employee = getattr(obj, "employee", None)
            if employee is None:
                return False
            if ctx.role_code == UserRole.MANAGER:
                return self._can_view_employee(ctx, employee)
            return False
        if self._is_device(obj) or self._is_device_assignment(obj):
            if ctx.role_code == UserRole.MANAGER:
                return True
            return False
        owner_id = getattr(obj, "owner_id", None)
        if ctx.role_code == UserRole.MANAGER:
            return owner_id == ctx.user.id or self.team_scope.is_in_team(
                ctx, owner_id
            )
        return owner_id == ctx.user.id

    def filter_queryset(self, queryset, ctx: TenantContext):
        label = queryset.model._meta.label
        if label in ("notifications.Notification", "notifications.DeviceToken"):
            if ctx.company is None or ctx.user is None:
                return queryset.none()
            queryset = queryset.filter(company_id=ctx.company.id)
            if label == "notifications.Notification":
                return queryset.filter(recipient_id=ctx.user.id)
            return queryset.filter(user_id=ctx.user.id)
        if ctx.is_super_admin:
            return queryset
        if ctx.company is None:
            return queryset.none()
        queryset = queryset.filter(company_id=ctx.company.id)
        if ctx.role_code == UserRole.COMPANY_ADMIN:
            return queryset
        label = queryset.model._meta.label
        if label == "employees.Employee":
            return self._filter_employees(queryset, ctx)
        if label == "attendance.Attendance":
            return self._filter_attendance(queryset, ctx)
        if label in ("leave.LeaveBalance", "leave.LeaveRequest"):
            return self._filter_attendance(queryset, ctx)
        if label == "documents.EmployeeDocument":
            return self._filter_attendance(queryset, ctx)
        if label == "leave.LeaveType":
            return queryset
        if label == "devices.Device":
            return self._filter_devices(queryset, ctx)
        if label == "devices.DeviceAssignment":
            return self._filter_device_assignments(queryset, ctx)
        if not hasattr(queryset.model, "visibility"):
            return queryset
        user_id = ctx.user.id
        return queryset.filter(
            Q(visibility="COMPANY") | Q(visibility="PRIVATE", owner_id=user_id)
        )

    def assert_same_tenant(self, ctx: TenantContext, related_user) -> bool:
        if related_user is None:
            return True
        if ctx.is_super_admin:
            return True
        if ctx.company is None:
            return False
        membership = related_user.get_active_membership()
        return bool(
            membership
            and membership.is_active
            and membership.company_id == ctx.company.id
        )

    def assert_company_owned(self, ctx: TenantContext, obj) -> bool:
        if obj is None:
            return True
        if ctx.is_super_admin:
            return True
        if ctx.company is None:
            return False
        return getattr(obj, "company_id", None) == ctx.company.id

    def _is_employee(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "employees.Employee"

    def _is_attendance(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "attendance.Attendance"

    def _is_leave_type(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "leave.LeaveType"

    def _is_leave_balance(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "leave.LeaveBalance"

    def _is_leave_request(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "leave.LeaveRequest"

    def _is_document(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "documents.EmployeeDocument"

    def _is_leave_employee_owned(self, obj) -> bool:
        return self._is_leave_balance(obj) or self._is_leave_request(obj)

    def _is_device(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "devices.Device"

    def _is_device_assignment(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "devices.DeviceAssignment"

    def _is_notification(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "notifications.Notification"

    def _is_device_token(self, obj) -> bool:
        return getattr(obj._meta, "label", "") == "notifications.DeviceToken"

    def _can_view_own_inbox_resource(self, ctx: TenantContext, obj) -> bool:
        if ctx.company is None or ctx.user is None:
            return False
        if getattr(obj, "company_id", None) != ctx.company.id:
            return False
        if self._is_notification(obj):
            return obj.recipient_id == ctx.user.id
        return obj.user_id == ctx.user.id

    def _active_device_assignment(self, device):
        from apps.devices.models import DeviceAssignment

        return (
            DeviceAssignment.objects.select_related("employee")
            .filter(device=device, returned_at__isnull=True)
            .first()
        )

    def _can_view_device(self, ctx: TenantContext, obj) -> bool:
        if ctx.role_code == UserRole.COMPANY_ADMIN:
            return True
        assignment = self._active_device_assignment(obj)
        if ctx.role_code == UserRole.MANAGER:
            if getattr(obj, "status", None) == "AVAILABLE":
                return True
            return assignment is not None and self._can_view_employee(
                ctx, assignment.employee
            )
        return (
            assignment is not None
            and assignment.employee.user_id == ctx.user.id
        )

    def _filter_devices(self, queryset, ctx: TenantContext):
        user_id = ctx.user.id
        if ctx.role_code == UserRole.MANAGER:
            my_id = self._actor_employee_id(ctx)
            query = Q(status="AVAILABLE")
            query |= Q(
                assignments__returned_at__isnull=True,
                assignments__employee__user_id=user_id,
            )
            if my_id is not None:
                query |= Q(
                    assignments__returned_at__isnull=True,
                    assignments__employee__manager_id=my_id,
                )
            return queryset.filter(query).distinct()
        return queryset.filter(
            assignments__returned_at__isnull=True,
            assignments__employee__user_id=user_id,
        ).distinct()

    def _filter_device_assignments(self, queryset, ctx: TenantContext):
        user_id = ctx.user.id
        if ctx.role_code == UserRole.MANAGER:
            my_id = self._actor_employee_id(ctx)
            query = Q(employee__user_id=user_id)
            if my_id is not None:
                query |= Q(employee__manager_id=my_id)
            return queryset.filter(query)
        return queryset.filter(employee__user_id=user_id)

    def _can_view_attendance(self, ctx: TenantContext, obj) -> bool:
        employee = getattr(obj, "employee", None)
        if employee is None:
            return False
        return self._can_view_employee(ctx, employee)

    def _filter_attendance(self, queryset, ctx: TenantContext):
        user_id = ctx.user.id
        if ctx.role_code == UserRole.MANAGER:
            my_id = self._actor_employee_id(ctx)
            query = Q(employee__user_id=user_id)
            if my_id is not None:
                query |= Q(employee__manager_id=my_id)
            return queryset.filter(query)
        return queryset.filter(employee__user_id=user_id)

    def _actor_employee_id(self, ctx: TenantContext):
        from apps.employees.models import Employee

        return (
            Employee.objects.filter(
                company_id=ctx.company.id, user_id=ctx.user.id
            )
            .values_list("id", flat=True)
            .first()
        )

    def _is_direct_report(self, ctx: TenantContext, obj) -> bool:
        my_id = self._actor_employee_id(ctx)
        return bool(my_id and obj.manager_id == my_id)

    def _can_view_employee(self, ctx: TenantContext, obj) -> bool:
        if ctx.role_code == UserRole.COMPANY_ADMIN:
            return True
        if obj.user_id == ctx.user.id:
            return True
        if ctx.role_code == UserRole.MANAGER:
            return self._is_direct_report(ctx, obj)
        return False

    def _can_change_employee(self, ctx: TenantContext, obj) -> bool:
        if ctx.role_code == UserRole.MANAGER:
            return obj.user_id == ctx.user.id or self._is_direct_report(ctx, obj)
        return False

    def _filter_employees(self, queryset, ctx: TenantContext):
        user_id = ctx.user.id
        if ctx.role_code == UserRole.MANAGER:
            my_id = self._actor_employee_id(ctx)
            query = Q(user_id=user_id)
            if my_id is not None:
                query |= Q(manager_id=my_id)
            return queryset.filter(query)
        return queryset.filter(user_id=user_id)

    def _can_view_private(self, ctx: TenantContext, owner_id) -> bool:
        if ctx.role_code == UserRole.COMPANY_ADMIN:
            return True
        if owner_id == ctx.user.id:
            return True
        if ctx.role_code == UserRole.MANAGER:
            return self.team_scope.is_in_team(ctx, owner_id)
        return False
