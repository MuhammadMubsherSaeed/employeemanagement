from django.core.exceptions import FieldDoesNotExist
from rest_framework.exceptions import NotFound, PermissionDenied

from apps.common.authorization import ObjectAuthorization
from apps.common.responses import success_response
from apps.common.tenancy import get_tenant_context


class EnvelopeMixin:
    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(queryset if page is None else page, many=True)
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return success_response(data=serializer.data)

    def retrieve(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_object())
        return success_response(data=serializer.data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        body = self.get_read_serializer(serializer.instance)
        return success_response(data=body.data, message="Created.")

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        body = self.get_read_serializer(serializer.instance)
        return success_response(data=body.data, message="Updated.")

    def destroy(self, request, *args, **kwargs):
        self.get_object().delete()
        return success_response(data={}, message="Deleted.")

    def get_read_serializer(self, instance):
        return self.get_serializer(instance)


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
