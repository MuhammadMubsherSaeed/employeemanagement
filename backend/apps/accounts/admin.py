from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django.db.models.deletion import ProtectedError

from apps.accounts.models import Permission, Role, User


class UserAdminCreationForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("email",)


class UserAdminChangeForm(UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User
        fields = "__all__"


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    form = UserAdminChangeForm
    add_form = UserAdminCreationForm
    ordering = ("email",)
    list_display = (
        "email",
        "first_name",
        "last_name",
        "role",
        "is_staff",
        "is_active",
        "is_superuser",
    )
    list_filter = ("role", "is_staff", "is_active", "is_superuser")
    search_fields = ("email", "first_name", "last_name")
    readonly_fields = ("last_login", "created_at", "updated_at")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal", {"fields": ("first_name", "last_name")}),
        (
            "Permissions",
            {
                "fields": (
                    "role",
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Dates", {"fields": ("last_login", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "password1", "password2", "role"),
            },
        ),
    )


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "scope", "is_system_role")
    list_filter = ("scope", "is_system_role")
    search_fields = ("code", "name")
    filter_horizontal = ("permissions",)

    def has_delete_permission(self, request, obj=None) -> bool:
        if obj is not None and obj.is_system_role:
            return False
        return super().has_delete_permission(request, obj)

    def delete_model(self, request, obj):
        if obj.is_system_role:
            raise ProtectedError("System roles cannot be deleted.", [obj])
        super().delete_model(request, obj)


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "module")
    list_filter = ("module",)
    search_fields = ("code", "name")
