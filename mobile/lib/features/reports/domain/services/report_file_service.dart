import 'dart:io';

import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class ReportFileService {
  Future<ReportSavedFile> save(ReportExportFile file);

  Future<void> share(ReportSavedFile file);

  Future<bool> open(ReportSavedFile file);
}

class PathProviderReportFileService implements ReportFileService {
  const PathProviderReportFileService();

  @override
  Future<ReportSavedFile> save(ReportExportFile file) async {
    final Directory directory = await getTemporaryDirectory();
    final String filename = _safeFilename(file.filename);
    final File saved = File('${directory.path}${Platform.pathSeparator}$filename');
    await saved.writeAsBytes(file.bytes, flush: true);
    return ReportSavedFile(
      path: saved.path,
      filename: filename,
      mimeType: file.mimeType,
    );
  }

  @override
  Future<void> share(ReportSavedFile file) {
    return Share.shareXFiles(
      <XFile>[
        XFile(file.path, mimeType: file.mimeType, name: file.filename),
      ],
    );
  }

  @override
  Future<bool> open(ReportSavedFile file) {
    return launchUrl(
      Uri.file(file.path),
      mode: LaunchMode.externalApplication,
    );
  }

  String _safeFilename(String raw) {
    final String trimmed = raw.trim().replaceAll(RegExp(r'[\\/]+'), '_');
    if (trimmed.isEmpty) {
      return 'report.bin';
    }
    return trimmed;
  }
}
