from drf_spectacular.utils import OpenApiExample, OpenApiResponse, extend_schema
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.serializers import (
    CurrentUserSerializer,
    ForgotPasswordSerializer,
    LoginSerializer,
    LogoutSerializer,
    RefreshTokenSerializer,
    ResetPasswordSerializer,
)
from apps.accounts.services import AuthenticationService, PasswordResetService
from apps.accounts.throttles import (
    AuthLoginThrottle,
    AuthPasswordThrottle,
    AuthRefreshThrottle,
)
from apps.common.responses import success_response

_auth = AuthenticationService()
_passwords = PasswordResetService()


class LoginView(APIView):
    permission_classes = (AllowAny,)
    throttle_classes = (AuthLoginThrottle,)
    authentication_classes = ()

    @extend_schema(
        tags=["Authentication"],
        request=LoginSerializer,
        responses={
            200: OpenApiResponse(description="Login successful."),
            401: OpenApiResponse(description="Invalid credentials."),
            403: OpenApiResponse(description="Inactive account."),
        },
        examples=[
            OpenApiExample(
                "Login",
                value={"email": "user@example.com", "password": "your-password"},
                request_only=True,
            )
        ],
    )
    def post(self, request, **_kwargs):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = _auth.login(
            email=serializer.validated_data["email"],
            password=serializer.validated_data["password"],
        )
        return success_response(data=data, message="Login successful.")


class RefreshView(APIView):
    permission_classes = (AllowAny,)
    throttle_classes = (AuthRefreshThrottle,)
    authentication_classes = ()

    @extend_schema(
        tags=["Authentication"],
        request=RefreshTokenSerializer,
        responses={200: OpenApiResponse(description="Token refreshed.")},
    )
    def post(self, request, **_kwargs):
        serializer = RefreshTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = _auth.refresh(serializer.validated_data["refresh"])
        return success_response(data=data, message="Token refreshed successfully.")


class LogoutView(APIView):
    permission_classes = (IsAuthenticated,)
    throttle_classes = (AuthRefreshThrottle,)

    @extend_schema(
        tags=["Authentication"],
        request=LogoutSerializer,
        responses={200: OpenApiResponse(description="Logout successful.")},
    )
    def post(self, request, **_kwargs):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _auth.logout(serializer.validated_data["refresh"])
        return success_response(data={}, message="Logout successful.")


class CurrentUserView(APIView):
    permission_classes = (IsAuthenticated,)

    @extend_schema(
        tags=["Authentication"],
        responses={200: CurrentUserSerializer},
    )
    def get(self, request, **_kwargs):
        return success_response(
            data=_auth.current_user(request.user),
            message="User retrieved successfully.",
        )


class ForgotPasswordView(APIView):
    permission_classes = (AllowAny,)
    throttle_classes = (AuthPasswordThrottle,)
    authentication_classes = ()

    @extend_schema(
        tags=["Authentication"],
        request=ForgotPasswordSerializer,
        responses={200: OpenApiResponse(description="Generic success.")},
        examples=[
            OpenApiExample(
                "Forgot password",
                value={"email": "user@example.com"},
                request_only=True,
            )
        ],
    )
    def post(self, request, **_kwargs):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _passwords.request_reset(serializer.validated_data["email"])
        return success_response(
            data={},
            message=(
                "If an account exists for this email, password reset "
                "instructions have been sent."
            ),
        )


class ResetPasswordView(APIView):
    permission_classes = (AllowAny,)
    throttle_classes = (AuthPasswordThrottle,)
    authentication_classes = ()

    @extend_schema(
        tags=["Authentication"],
        request=ResetPasswordSerializer,
        responses={200: OpenApiResponse(description="Password reset successful.")},
    )
    def post(self, request, **_kwargs):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _passwords.reset_password(
            uid=serializer.validated_data["uid"],
            token=serializer.validated_data["token"],
            new_password=serializer.validated_data["new_password"],
        )
        return success_response(data={}, message="Password reset successful.")
