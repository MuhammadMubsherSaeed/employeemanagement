enum AttendanceStatus {
  present('PRESENT', 'Present'),
  absent('ABSENT', 'Absent'),
  late('LATE', 'Late'),
  halfDay('HALF_DAY', 'Half day'),
  leave('LEAVE', 'Leave'),
  holiday('HOLIDAY', 'Holiday'),
  weekend('WEEKEND', 'Weekend'),
  unknown('UNKNOWN', 'Unknown');

  const AttendanceStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AttendanceStatus fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final AttendanceStatus item in AttendanceStatus.values) {
      if (item != AttendanceStatus.unknown && item.apiValue == value) {
        return item;
      }
    }
    return AttendanceStatus.unknown;
  }
}

/// UI punch-clock state derived from timestamps, not a backend status.
enum PunchState {
  none,
  checkedIn,
  checkedOut,
}
