import 'package:flutter_base/features/reports/presentation/providers/report_export_controller.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void invalidateReportProviders(Ref ref) {
  ref.invalidate(reportListControllerProvider);
  ref.invalidate(reportExportControllerProvider);
}
