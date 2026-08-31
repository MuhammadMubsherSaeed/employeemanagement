import 'package:file_picker/file_picker.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';

const int kLeaveAttachmentMaxBytes = 5 * 1024 * 1024;
const List<String> kLeaveAttachmentExtensions = <String>[
  'pdf',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'doc',
  'docx',
];

abstract class LeaveAttachmentPicker {
  Future<LeaveAttachmentFile?> pick();
}

class FilePickerLeaveAttachmentPicker implements LeaveAttachmentPicker {
  @override
  Future<LeaveAttachmentFile?> pick() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kLeaveAttachmentExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile file = result.files.first;
    if (file.path == null || file.path!.isEmpty) {
      return null;
    }
    return LeaveAttachmentFile(
      path: file.path!,
      name: file.name,
      size: file.size,
    );
  }
}

String? validateLeaveAttachment(LeaveAttachmentFile file) {
  final String ext = file.name.contains('.')
      ? file.name.split('.').last.toLowerCase()
      : '';
  if (!kLeaveAttachmentExtensions.contains(ext)) {
    return 'Attachment must be a PDF, image, or Word document.';
  }
  if (file.size > kLeaveAttachmentMaxBytes) {
    return 'Attachment is too large.';
  }
  if (file.path.isEmpty) {
    return 'The selected file could not be read.';
  }
  return null;
}
