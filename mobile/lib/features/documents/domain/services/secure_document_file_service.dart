import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class SecureDocumentFileService {
  Future<String> writeTemporary(DownloadedBytes file);

  Future<bool> openPath(String path);

  Future<void> sharePath(String path, {required String mimeType, required String name});

  Future<void> deletePath(String path);
}

class PathProviderSecureDocumentFileService implements SecureDocumentFileService {
  const PathProviderSecureDocumentFileService();

  @override
  Future<String> writeTemporary(DownloadedBytes file) async {
    final Directory directory = await getTemporaryDirectory();
    final String filename = sanitizeDisplayName(file.filename);
    final File saved = File('${directory.path}${Platform.pathSeparator}$filename');
    final List<int> bytes = file.bytes;
    await saved.writeAsBytes(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      flush: true,
    );
    return saved.path;
  }

  @override
  Future<bool> openPath(String path) {
    return launchUrl(
      Uri.file(path),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> sharePath(
    String path, {
    required String mimeType,
    required String name,
  }) {
    return Share.shareXFiles(
      <XFile>[XFile(path, mimeType: mimeType, name: name)],
    );
  }

  @override
  Future<void> deletePath(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
