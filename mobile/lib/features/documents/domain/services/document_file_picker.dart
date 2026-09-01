import 'package:file_picker/file_picker.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';

abstract class DocumentFilePicker {
  Future<DocumentFile?> pick();
}

class FilePickerDocumentFilePicker implements DocumentFilePicker {
  @override
  Future<DocumentFile?> pick() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kDocumentExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile file = result.files.first;
    if (file.path == null || file.path!.isEmpty) {
      return null;
    }
    return DocumentFile(
      path: file.path!,
      name: file.name,
      size: file.size,
    );
  }
}
