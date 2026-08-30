"""Attendance endpoints use apps.common.permissions and rbac_catalog codes.

attendance.view       list, retrieve, me, summary, holiday reads
attendance.check_in   POST /attendance/check-in/
attendance.check_out  POST /attendance/check-out/
attendance.manage     reserved for future manual corrections (not exposed here)
settings.manage       holiday writes (company calendar)
"""

ATTENDANCE_VIEW = "attendance.view"
ATTENDANCE_CHECK_IN = "attendance.check_in"
ATTENDANCE_CHECK_OUT = "attendance.check_out"
HOLIDAY_WRITE_PERMISSION = "settings.manage"
