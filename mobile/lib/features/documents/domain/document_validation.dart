import 'package:flutter_base/features/documents/domain/entities/document.dart';

const int kMaxDocumentUploadBytes = 10 * 1024 * 1024;
const int kMaxProfileImageBytes = 2 * 1024 * 1024;

const List<String> kDocumentExtensions = <String>[
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'jpg',
  'jpeg',
  'png',
];

const List<String> kProfileImageExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'webp',
];

const Set<String> kBlockedExtensions = <String>{
  'exe',
  'bat',
  'cmd',
  'com',
  'msi',
  'js',
  'sh',
  'ps1',
  'dll',
  'scr',
  'vbs',
};

String? validateDocumentFile({
  required String name,
  required int size,
}) {
  final String ext = _extension(name);
  if (ext.isEmpty || kBlockedExtensions.contains(ext)) {
    return 'This file type is not allowed.';
  }
  if (!kDocumentExtensions.contains(ext)) {
    return 'Document must be a PDF, Word, Excel, JPEG, or PNG file.';
  }
  if (size <= 0) {
    return 'The selected file could not be read.';
  }
  if (size > kMaxDocumentUploadBytes) {
    return 'This file is too large.';
  }
  return null;
}

String? validateProfileImageFile({
  required String name,
  required int size,
}) {
  final String ext = _extension(name);
  if (ext.isEmpty || kBlockedExtensions.contains(ext)) {
    return 'This file type is not allowed.';
  }
  if (!kProfileImageExtensions.contains(ext)) {
    return 'Profile image must be a JPEG, PNG, or WebP.';
  }
  if (size <= 0) {
    return 'The selected file could not be read.';
  }
  if (size > kMaxProfileImageBytes) {
    return 'This file is too large.';
  }
  return null;
}

String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String sanitizeDisplayName(String raw) {
  final String trimmed = raw.trim().replaceAll(RegExp(r'[\\/]+'), '_');
  if (trimmed.isEmpty) {
    return 'document';
  }
  return trimmed;
}

String _extension(String name) {
  if (!name.contains('.')) {
    return '';
  }
  return name.split('.').last.toLowerCase();
}

bool documentLooksLikeImage(DownloadedBytes file) {
  if (file.mimeType.startsWith('image/')) {
    return true;
  }
  final String name = file.filename.toLowerCase();
  return name.endsWith('.png') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.webp');
}
