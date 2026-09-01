import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/services/secure_document_file_service.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_error_mapper.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.employeeId,
    required this.documentId,
  });

  final String employeeId;
  final String documentId;

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  DownloadedBytes? _file;
  String? _tempPath;
  Object? _error;
  bool _loading = true;
  late final SecureDocumentFileService _files;

  @override
  void initState() {
    super.initState();
    _files = ref.read(secureDocumentFileServiceProvider);
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    final String? path = _tempPath;
    if (path != null) {
      unawaited(_files.deletePath(path));
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DownloadedBytes file =
          await ref.read(downloadEmployeeDocumentProvider)(
        employeeId: widget.employeeId,
        documentId: widget.documentId,
      );
      String? path;
      if (!documentLooksLikeImage(file)) {
        path = await ref.read(secureDocumentFileServiceProvider).writeTemporary(
              file,
            );
      }
      if (!mounted) {
        if (path != null) {
          await ref.read(secureDocumentFileServiceProvider).deletePath(path);
        }
        return;
      }
      setState(() {
        _file = file;
        _tempPath = path;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openExternal() async {
    final String? path = _tempPath;
    if (path == null) {
      return;
    }
    final bool ok =
        await ref.read(secureDocumentFileServiceProvider).openPath(path);
    if (!mounted) {
      return;
    }
    if (!ok) {
      context.showSnack('No application could open this file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_file?.filename ?? 'Preview')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const AppLoader();
    }
    if (_error != null) {
      return AppErrorWidget(
        message: DocumentErrorMapper.message(_error!),
        onRetry: _load,
      );
    }
    final DownloadedBytes? file = _file;
    if (file == null) {
      return const AppErrorWidget(message: 'The file could not be loaded.');
    }
    if (documentLooksLikeImage(file)) {
      return InteractiveViewer(
        child: Center(
          child: Image.memory(
            file.bytes is Uint8List
                ? file.bytes as Uint8List
                : Uint8List.fromList(file.bytes),
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.insert_drive_file_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Preview is not available for this file type.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Open with another app',
            onPressed: _openExternal,
          ),
        ],
      ),
    );
  }
}
