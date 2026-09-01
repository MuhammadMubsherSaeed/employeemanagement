from django.db import migrations, models


_ACTIONS = [
    "EMPLOYEE_CREATED",
    "EMPLOYEE_UPDATED",
    "EMPLOYEE_DEACTIVATED",
    "DEPARTMENT_CREATED",
    "DEPARTMENT_UPDATED",
    "LEAVE_SUBMITTED",
    "LEAVE_APPROVED",
    "LEAVE_REJECTED",
    "LEAVE_CANCELLED",
    "DEVICE_ASSIGNED",
    "DEVICE_RETURNED",
    "ROLE_CHANGED",
    "PERMISSION_CHANGED",
    "SETTINGS_CHANGED",
    "DOCUMENT_UPLOADED",
    "DOCUMENT_DOWNLOADED",
    "DOCUMENT_DELETED",
    "PROFILE_IMAGE_UPDATED",
    "LEAVE_ATTACHMENT_UPLOADED",
    "LEAVE_ATTACHMENT_DELETED",
]

_ENTITY_TYPES = [
    "EMPLOYEE",
    "DEPARTMENT",
    "LEAVE_REQUEST",
    "DEVICE",
    "USER",
    "ROLE",
    "COMPANY_SETTINGS",
    "EMPLOYEE_DOCUMENT",
]


class Migration(migrations.Migration):
    dependencies = [
        ("audit_logs", "0001_initial"),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name="auditlog",
            name="audit_log_valid_action",
        ),
        migrations.RemoveConstraint(
            model_name="auditlog",
            name="audit_log_valid_entity_type",
        ),
        migrations.AlterField(
            model_name="auditlog",
            name="action",
            field=models.CharField(
                choices=[
                    ("EMPLOYEE_CREATED", "Employee created"),
                    ("EMPLOYEE_UPDATED", "Employee updated"),
                    ("EMPLOYEE_DEACTIVATED", "Employee deactivated"),
                    ("DEPARTMENT_CREATED", "Department created"),
                    ("DEPARTMENT_UPDATED", "Department updated"),
                    ("LEAVE_SUBMITTED", "Leave submitted"),
                    ("LEAVE_APPROVED", "Leave approved"),
                    ("LEAVE_REJECTED", "Leave rejected"),
                    ("LEAVE_CANCELLED", "Leave cancelled"),
                    ("DEVICE_ASSIGNED", "Device assigned"),
                    ("DEVICE_RETURNED", "Device returned"),
                    ("ROLE_CHANGED", "Role changed"),
                    ("PERMISSION_CHANGED", "Permission changed"),
                    ("SETTINGS_CHANGED", "Settings changed"),
                    ("DOCUMENT_UPLOADED", "Document uploaded"),
                    ("DOCUMENT_DOWNLOADED", "Document downloaded"),
                    ("DOCUMENT_DELETED", "Document deleted"),
                    ("PROFILE_IMAGE_UPDATED", "Profile image updated"),
                    ("LEAVE_ATTACHMENT_UPLOADED", "Leave attachment uploaded"),
                    ("LEAVE_ATTACHMENT_DELETED", "Leave attachment deleted"),
                ],
                max_length=32,
            ),
        ),
        migrations.AlterField(
            model_name="auditlog",
            name="entity_type",
            field=models.CharField(
                choices=[
                    ("EMPLOYEE", "Employee"),
                    ("DEPARTMENT", "Department"),
                    ("LEAVE_REQUEST", "Leave request"),
                    ("DEVICE", "Device"),
                    ("USER", "User"),
                    ("ROLE", "Role"),
                    ("COMPANY_SETTINGS", "Company settings"),
                    ("EMPLOYEE_DOCUMENT", "Employee document"),
                ],
                max_length=32,
            ),
        ),
        migrations.AddConstraint(
            model_name="auditlog",
            constraint=models.CheckConstraint(
                condition=models.Q(("action__in", _ACTIONS)),
                name="audit_log_valid_action",
            ),
        ),
        migrations.AddConstraint(
            model_name="auditlog",
            constraint=models.CheckConstraint(
                condition=models.Q(("entity_type__in", _ENTITY_TYPES)),
                name="audit_log_valid_entity_type",
            ),
        ),
    ]
