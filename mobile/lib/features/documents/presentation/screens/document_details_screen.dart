import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_error_mapper.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter_base/features/documents/presentation/states/document_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocumentDetailsScreen extends ConsumerWidget {
  const DocumentDetailsScreen({
    super.key,
    required this.employeeId,
    required this.documentId,
  });

  final String employeeId;
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);
    final DocumentAccess access = DocumentAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );
    final DocumentMutationState mutation =
        ref.watch(documentMutationControllerProvider);
    final AsyncValue<EmployeeDocument> async = ref.watch(
      documentDetailsProvider(
        DocumentLookup(employeeId: employeeId, documentId: documentId),
      ),
    );

    return async.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: AppErrorWidget(
          message: DocumentErrorMapper.message(error),
          onRetry: () => ref.invalidate(
            documentDetailsProvider(
              DocumentLookup(employeeId: employeeId, documentId: documentId),
            ),
          ),
        ),
      ),
      data: (EmployeeDocument document) {
        return Scaffold(
          appBar: AppBar(title: Text(document.fileName)),
          body: ListView(
            padding: AppSpacing.screen,
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _row(context, 'Type', document.documentType.label),
                    _row(context, 'File name', document.fileName),
                    _row(context, 'MIME type', document.mimeType),
                    _row(context, 'Size', formatFileSize(document.fileSize)),
                    _row(
                      context,
                      'Uploaded by',
                      document.uploadedBy?.email ?? '—',
                    ),
                    _row(
                      context,
                      'Uploaded',
                      document.createdAt == null
                          ? '—'
                          : AppDateFormatter.dateTime(document.createdAt!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Preview',
                isLoading: mutation.downloading,
                onPressed: mutation.isBusy
                    ? null
                    : () => context.push(
                          AppRoutes.employeeDocumentPreview(
                            employeeId,
                            documentId,
                          ),
                        ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Download',
                variant: AppButtonVariant.outlined,
                isLoading: mutation.downloading,
                onPressed: mutation.isBusy
                    ? null
                    : () => _download(context, ref, document),
              ),
              if (access.canDelete) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Delete',
                  variant: AppButtonVariant.text,
                  isLoading: mutation.deleting,
                  onPressed: mutation.isBusy
                      ? null
                      : () => _delete(context, ref, document),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    EmployeeDocument document,
  ) async {
    final DownloadedBytes? file =
        await ref.read(documentMutationControllerProvider.notifier).download(
              employeeId: employeeId,
              documentId: documentId,
            );
    if (!context.mounted) {
      return;
    }
    if (file == null) {
      final String? error = ref.read(documentMutationControllerProvider).error;
      context.showSnack(error ?? 'Unable to download the file.');
      return;
    }
    try {
      final String path =
          await ref.read(secureDocumentFileServiceProvider).writeTemporary(file);
      await ref.read(secureDocumentFileServiceProvider).sharePath(
            path,
            mimeType: file.mimeType,
            name: file.filename,
          );
      await ref.read(secureDocumentFileServiceProvider).deletePath(path);
    } catch (_) {
      if (context.mounted) {
        context.showSnack('Unable to save the file.');
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EmployeeDocument document,
  ) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete document',
      message: 'Delete ${document.fileName}? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true) {
      return;
    }
    final bool ok = await ref
        .read(documentMutationControllerProvider.notifier)
        .delete(employeeId: employeeId, documentId: documentId);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      context.showSnack('Document deleted.');
      context.pop();
      return;
    }
    final String? error = ref.read(documentMutationControllerProvider).error;
    context.showSnack(error ?? 'Unable to delete the document.');
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
