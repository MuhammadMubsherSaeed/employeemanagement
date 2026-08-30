from rest_framework.throttling import ScopedRateThrottle


class AuthLoginThrottle(ScopedRateThrottle):
    scope = "auth_login"


class AuthRefreshThrottle(ScopedRateThrottle):
    scope = "auth_refresh"


class AuthPasswordThrottle(ScopedRateThrottle):
    scope = "auth_password"
