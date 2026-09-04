import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter_base/features/documents/presentation/states/document_list_state.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeeDocumentsScreen extends ConsumerStatefulWidget {
  const EmployeeDocumentsScreen({
    super.key,
    required this.employeeId,
    this.embedded = false,
  });

  final String employeeId;
  final bool embedded;

  @override
  ConsumerState<EmployeeDocumentsScreen> createState() =>
      _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState
    extends ConsumerState<EmployeeDocumentsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(employeeDocumentsProvider(widget.employeeId).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double max = _scroll.position.maxScrollExtent;
    if (max <= 0) {
      return;
    }
    if (_scroll.position.pixels > max - 240) {
      ref.read(employeeDocumentsProvider(widget.employeeId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentAccess access = DocumentAccess(
      ref.watch(authorizationProvider),
    );
    final DocumentListState list =
        ref.watch(employeeDocumentsProvider(widget.employeeId));

    final Widget body = Column(
      children: <Widget>[
        Padding(
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.sm),
          child: EmployeeSearchBar(
            hintText: 'Search documents',
            onChanged: (String value) {
              ref
                  .read(employeeDocumentsProvider(widget.employeeId).notifier)
                  .setSearch(value);
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: FilterChip(
                  label: const Text('All'),
                  selected: list.query.documentType == null,
                  onSelected: (_) {
                    ref
                        .read(
                          employeeDocumentsProvider(widget.employeeId).notifier,
                        )
                        .setType(null);
                  },
                ),
              ),
              ...DocumentType.selectable.take(8).map(
                    (DocumentType type) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        label: Text(type.label),
                        selected: list.query.documentType == type,
                        onSelected: (_) {
                          ref
                              .read(
                                employeeDocumentsProvider(widget.employeeId)
                                    .notifier,
                              )
                              .setType(
                                list.query.documentType == type ? null : type,
                              );
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(child: _list(context, list)),
      ],
    );

    if (widget.embedded) {
      return Stack(
        children: <Widget>[
          body,
          if (access.canUpload)
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: FloatingActionButton(
                onPressed: () => context.push(
                  AppRoutes.employeeDocumentUpload(widget.employeeId),
                ),
                child: const Icon(Icons.upload_file_outlined),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: access.canUpload
          ? FloatingActionButton(
              onPressed: () => context.push(
                AppRoutes.employeeDocumentUpload(widget.employeeId),
              ),
              child: const Icon(Icons.upload_file_outlined),
            )
          : null,
      body: body,
    );
  }

  Widget _list(
    BuildContext context,
    DocumentListState list,
  ) {
    if (list.isInitialLoading) {
      return const AppLoader();
    }
    if (list.error != null && list.items.isEmpty) {
      return AppErrorWidget(
        message: list.error!,
        onRetry: () => ref
            .read(employeeDocumentsProvider(widget.employeeId).notifier)
            .loadInitial(),
      );
    }
    if (list.isEmpty) {
      return const AppEmptyState(
        title: 'No documents',
        subtitle: 'Upload a file to get started.',
        icon: Icons.folder_open_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(employeeDocumentsProvider(widget.employeeId).notifier).refresh(),
      child: ListView.builder(
        controller: _scroll,
        padding: AppSpacing.screen,
        itemCount: list.items.length + (list.isLoadingMore ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= list.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppLoader(),
            );
          }
          final EmployeeDocument document = list.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => context.push(
                AppRoutes.employeeDocument(
                  widget.employeeId,
                  document.id,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(document.documentType.icon),
                title: Text(document.fileName),
                subtitle: Text(
                  <String>[
                    document.documentType.label,
                    formatFileSize(document.fileSize),
                    if (document.createdAt != null)
                      AppDateFormatter.date(document.createdAt!),
                    if (document.uploadedBy != null) document.uploadedBy!.email,
                  ].join(' · '),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
