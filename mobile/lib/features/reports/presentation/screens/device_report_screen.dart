import 'package:flutter/material.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/presentation/screens/reports_screen.dart';

class DeviceReportScreen extends StatelessWidget {
  const DeviceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportListScreen(kind: ReportKind.devices);
  }
}
