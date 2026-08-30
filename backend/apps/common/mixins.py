from django.core.exceptions import FieldDoesNotExist
from rest_framework.exceptions import NotFound, PermissionDenied

from apps.common.authorization import ObjectAuthorization
from apps.common.tenancy import get_tenant_context


class TenantAwareQuerySetMixin:
    """Restrict querysets to the authenticated tenant.

    Super admins see all rows (platform). Users without an active company
    membership see nothing. Cross-company IDs therefore 404, not 403.

    perform_create always sets company from tenant context. owner is set
    only when the model has that field (legacy tenancy probe records).
    """

    tenant_field = "company"
    object_authorization_class = ObjectAuthorization

    def get_tenant_context(self):
        return get_tenant_context(self.request)

    def get_queryset(self):
        queryset = super().get_queryset()
        ctx = self.get_tenant_context()
        return self.object_authorization_class().filter_queryset(queryset, ctx)

    def perform_create(self, serializer):
        ctx = self.get_tenant_context()
        if ctx.company is None:
            raise PermissionDenied("You do not have access to this company.")
        extras = {"company": ctx.company}
        try:
            serializer.Meta.model._meta.get_field("owner")
            extras["owner"] = ctx.user
        except FieldDoesNotExist:
            pass
        serializer.save(**extras)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        ctx = self.get_tenant_context()
        authz = self.object_authorization_class()
        if not authz.can_view(ctx, obj):
            raise NotFound()
        if request.method not in ("GET", "HEAD", "OPTIONS") and not authz.can_change(
            ctx, obj
        ):
            raise PermissionDenied(
                "You do not have permission to perform this action."
            )
