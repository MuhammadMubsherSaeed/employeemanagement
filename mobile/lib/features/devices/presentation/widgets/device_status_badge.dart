import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';

class DeviceStatusBadge extends StatelessWidget {
  const DeviceStatusBadge({super.key, required this.status});

  final DeviceStatus status;

  static AppBadgeTone toneOf(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.available => AppBadgeTone.success,
      DeviceStatus.assigned => AppBadgeTone.info,
      DeviceStatus.maintenance => AppBadgeTone.warning,
      DeviceStatus.retired => AppBadgeTone.neutral,
      DeviceStatus.lost => AppBadgeTone.error,
      DeviceStatus.unknown => AppBadgeTone.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status.label, tone: toneOf(status));
  }
}
