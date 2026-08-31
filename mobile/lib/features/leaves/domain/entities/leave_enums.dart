enum LeaveTypeStatus {
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive'),
  unknown('UNKNOWN', 'Unknown');

  const LeaveTypeStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LeaveTypeStatus fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final LeaveTypeStatus item in LeaveTypeStatus.values) {
      if (item != LeaveTypeStatus.unknown && item.apiValue == value) {
        return item;
      }
    }
    return LeaveTypeStatus.unknown;
  }
}

enum LeaveRequestStatus {
  pending('PENDING', 'Pending'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  cancelled('CANCELLED', 'Cancelled'),
  unknown('UNKNOWN', 'Unknown');

  const LeaveRequestStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LeaveRequestStatus fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final LeaveRequestStatus item in LeaveRequestStatus.values) {
      if (item != LeaveRequestStatus.unknown && item.apiValue == value) {
        return item;
      }
    }
    return LeaveRequestStatus.unknown;
  }
}
