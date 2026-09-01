from __future__ import annotations

from apps.accounts.models import UserRole
from apps.companies.models import CompanyMembership
from apps.notifications.models import EntityType, NotificationType
from apps.notifications.services import NotificationService

_service = NotificationService()


def notify_leave_submitted(leave_request, *, actor=None) -> None:
    recipients = _leave_approvers(
        leave_request,
        exclude_user_id=actor.id if actor else None,
    )
    employee = leave_request.employee
    _service.create_notifications_for_users(
        company=leave_request.company,
        recipients=recipients,
        type=NotificationType.LEAVE_SUBMITTED,
        title="Leave request submitted",
        message=(
            f"{employee.first_name} {employee.last_name} submitted a leave request."
        ).strip(),
        entity_type=EntityType.LEAVE_REQUEST,
        entity_id=leave_request.id,
        metadata={"leave_status": leave_request.status},
        event_key_prefix=f"leave.request.created:{leave_request.id}",
        actor=actor,
    )


def notify_leave_approved(leave_request, *, actor=None) -> None:
    user = getattr(leave_request.employee, "user", None)
    if user is None or (actor is not None and user.id == actor.id):
        return
    _service.create_notification(
        company=leave_request.company,
        recipient=user,
        type=NotificationType.LEAVE_APPROVED,
        title="Leave request approved",
        message="Your leave request was approved.",
        entity_type=EntityType.LEAVE_REQUEST,
        entity_id=leave_request.id,
        metadata={"leave_status": leave_request.status},
        event_key=f"leave.request.approved:{leave_request.id}",
        actor=actor,
    )


def notify_leave_rejected(leave_request, *, actor=None) -> None:
    user = getattr(leave_request.employee, "user", None)
    if user is None or (actor is not None and user.id == actor.id):
        return
    _service.create_notification(
        company=leave_request.company,
        recipient=user,
        type=NotificationType.LEAVE_REJECTED,
        title="Leave request rejected",
        message="Your leave request was rejected.",
        entity_type=EntityType.LEAVE_REQUEST,
        entity_id=leave_request.id,
        metadata={"leave_status": leave_request.status},
        event_key=f"leave.request.rejected:{leave_request.id}",
        actor=actor,
    )


def notify_leave_cancelled(leave_request, *, actor=None) -> None:
    actor_id = getattr(actor, "id", None)
    employee_user = getattr(leave_request.employee, "user", None)
    recipients = []
    if employee_user is not None and employee_user.id != actor_id:
        recipients.append(employee_user)
    if employee_user is None or (actor_id and employee_user.id == actor_id):
        recipients.extend(
            _leave_approvers(leave_request, exclude_user_id=actor_id)
        )
    _service.create_notifications_for_users(
        company=leave_request.company,
        recipients=recipients,
        type=NotificationType.LEAVE_CANCELLED,
        title="Leave request cancelled",
        message="A leave request was cancelled.",
        entity_type=EntityType.LEAVE_REQUEST,
        entity_id=leave_request.id,
        metadata={"leave_status": leave_request.status},
        event_key_prefix=f"leave.request.cancelled:{leave_request.id}",
        actor=actor,
    )


def notify_device_assigned(device, employee, *, actor=None) -> None:
    user = getattr(employee, "user", None)
    if user is None or (actor is not None and user.id == actor.id):
        return
    _service.create_notification(
        company=device.company,
        recipient=user,
        type=NotificationType.DEVICE_ASSIGNED,
        title="Device assigned",
        message=f"{device.asset_code} was assigned to you.",
        entity_type=EntityType.DEVICE,
        entity_id=device.id,
        metadata={"device_asset_code": device.asset_code},
        event_key=f"device.assigned:{device.id}:{employee.id}",
        actor=actor,
    )


def notify_device_returned(device, employee, *, actor=None) -> None:
    user = getattr(employee, "user", None)
    if user is None or (actor is not None and user.id == actor.id):
        return
    _service.create_notification(
        company=device.company,
        recipient=user,
        type=NotificationType.DEVICE_RETURNED,
        title="Device returned",
        message=f"{device.asset_code} was marked returned.",
        entity_type=EntityType.DEVICE,
        entity_id=device.id,
        metadata={"device_asset_code": device.asset_code},
        event_key=f"device.returned:{device.id}:{employee.id}",
        actor=actor,
    )


def _leave_approvers(leave_request, *, exclude_user_id=None) -> list:
    users = []
    manager = getattr(leave_request.employee, "manager", None)
    manager_user = getattr(manager, "user", None) if manager is not None else None
    if manager_user is not None and manager_user.id != exclude_user_id:
        users.append(manager_user)
        return users
    memberships = CompanyMembership.objects.filter(
        company_id=leave_request.company_id,
        is_active=True,
        role__code=UserRole.COMPANY_ADMIN,
    ).select_related("user")
    for membership in memberships:
        if membership.user_id == exclude_user_id:
            continue
        users.append(membership.user)
    return users
