enum DeviceStatus {
  available('AVAILABLE', 'Available'),
  assigned('ASSIGNED', 'Assigned'),
  maintenance('MAINTENANCE', 'Maintenance'),
  retired('RETIRED', 'Retired'),
  lost('LOST', 'Lost'),
  unknown('UNKNOWN', 'Unknown');

  const DeviceStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get canAssign => this == DeviceStatus.available;

  bool get canReturn => this == DeviceStatus.assigned;

  /// Status values the update API may accept from the current status.
  /// ASSIGNED and AVAILABLE-from-ASSIGNED are never included — use assign/return.
  List<DeviceStatus> get allowedUpdateStatuses {
    switch (this) {
      case DeviceStatus.available:
        return const <DeviceStatus>[
          DeviceStatus.maintenance,
          DeviceStatus.retired,
          DeviceStatus.lost,
        ];
      case DeviceStatus.assigned:
        return const <DeviceStatus>[DeviceStatus.lost];
      case DeviceStatus.maintenance:
        return const <DeviceStatus>[
          DeviceStatus.available,
          DeviceStatus.retired,
        ];
      case DeviceStatus.retired:
      case DeviceStatus.lost:
      case DeviceStatus.unknown:
        return const <DeviceStatus>[];
    }
  }

  static DeviceStatus fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final DeviceStatus item in DeviceStatus.values) {
      if (item != DeviceStatus.unknown && item.apiValue == value) {
        return item;
      }
    }
    return DeviceStatus.unknown;
  }
}
