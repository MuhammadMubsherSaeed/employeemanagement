import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_status_badge.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
  });

  final Device device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String subtitle = <String>[
      device.type,
      if (device.manufacturer.isNotEmpty) device.manufacturer,
      if (device.model.isNotEmpty) device.model,
    ].join(' · ');
    return Semantics(
      button: onTap != null,
      label: '${device.assetCode}, ${device.status.label}',
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(device.assetCode, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: text.bodyMedium),
                  if (device.serialNumber != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'S/N ${device.serialNumber}',
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            DeviceStatusBadge(status: device.status),
          ],
        ),
      ),
    );
  }
}
