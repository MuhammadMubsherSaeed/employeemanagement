import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/presentation/states/report_export_state.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({
    super.key,
    required this.state,
    required this.onSelected,
    this.enabled = true,
  });

  final ReportExportState state;
  final ValueChanged<ReportExportFormat> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool busy = state.isBusy;
    return Semantics(
      button: true,
      enabled: enabled && !busy,
      label: busy ? 'Exporting report' : 'Export report',
      child: PopupMenuButton<ReportExportFormat>(
        tooltip: 'Export',
        enabled: enabled && !busy,
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return ReportExportFormat.values
              .map(
                (ReportExportFormat format) => PopupMenuItem<ReportExportFormat>(
                  value: format,
                  child: Text('Export ${format.label}'),
                ),
              )
              .toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.ios_share_outlined),
        ),
      ),
    );
  }
}

class ExportActionBar extends StatelessWidget {
  const ExportActionBar({
    super.key,
    required this.onShare,
    required this.onOpen,
  });

  final VoidCallback onShare;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Share',
            icon: Icons.share_outlined,
            onPressed: onShare,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            label: 'Open',
            variant: AppButtonVariant.outlined,
            icon: Icons.open_in_new,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}
