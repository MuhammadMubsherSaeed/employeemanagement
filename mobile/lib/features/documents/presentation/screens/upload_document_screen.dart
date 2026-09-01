import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter_base/features/documents/presentation/states/document_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  ConsumerState<UploadDocumentScreen> createState() =>
      _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  DocumentType _type = DocumentType.other;
  DocumentFile? _file;
  String? _fileError;

  Future<void> _pick() async {
    final DocumentFile? file =
        await ref.read(documentFilePickerProvider).pick();
    if (file == null) {
      return;
    }
    setState(() {
      _file = file;
      _fileError = validateDocumentFile(name: file.name, size: file.size);
    });
  }

  Future<void> _upload() async {
    final DocumentFile? file = _file;
    if (file == null) {
      setState(() => _fileError = 'Select a file to upload.');
      return;
    }
    final String? error = validateDocumentFile(name: file.name, size: file.size);
    if (error != null) {
      setState(() => _fileError = error);
      return;
    }
    final EmployeeDocument? result =
        await ref.read(documentMutationControllerProvider.notifier).upload(
              employeeId: widget.employeeId,
              documentType: _type,
              file: file,
              title: file.name,
            );
    if (!mounted) {
      return;
    }
    if (result != null) {
      context.showSnack('Document uploaded.');
      Navigator.of(context).pop();
      return;
    }
    final String? mutationError =
        ref.read(documentMutationControllerProvider).error;
    if (mutationError != null) {
      context.showSnack(mutationError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentMutationState mutation =
        ref.watch(documentMutationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload document')),
      body: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          AppDropdown<DocumentType>(
            key: ValueKey<String>('type-${_type.apiValue}'),
            label: 'Document type',
            value: _type,
            items: DocumentType.selectable
                .map(
                  (DocumentType item) => AppDropdownItem<DocumentType>(
                    value: item,
                    label: item.label,
                  ),
                )
                .toList(),
            onChanged: (DocumentType? value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file),
            title: Text(_file?.name ?? 'No file selected'),
            subtitle: _file == null
                ? const Text('PDF, Word, Excel, JPEG, or PNG')
                : Text(formatFileSize(_file!.size)),
            trailing: AppButton(
              label: 'Choose',
              variant: AppButtonVariant.outlined,
              expand: false,
              onPressed: mutation.uploading ? null : _pick,
            ),
          ),
          if (_fileError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _fileError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Upload',
            isLoading: mutation.uploading,
            onPressed: mutation.uploading ? null : _upload,
          ),
        ],
      ),
    );
  }
}
