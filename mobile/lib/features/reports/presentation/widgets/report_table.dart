import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_empty_state.dart';

const double kReportTabletBreakpoint = AppBreakpoints.medium;

class ReportColumn {
  const ReportColumn({
    required this.label,
    required this.value,
    this.cell,
    this.minWidth = 120,
  });

  final String label;
  final String Function(Object row) value;
  final Widget Function(BuildContext context, Object row)? cell;
  final double minWidth;
}

class ReportTable extends StatelessWidget {
  const ReportTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.emptyMessage,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.onRetry,
    this.onLoadMore,
    this.cardBuilder,
  });

  final List<ReportColumn> columns;
  final List<Object> rows;
  final String emptyMessage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final Widget Function(BuildContext context, Object row)? cardBuilder;

  @override
  Widget build(BuildContext context) {
    if (isLoading && rows.isEmpty) {
      return const AppLoader(message: 'Loading report…');
    }
    if (error != null && rows.isEmpty) {
      return AppErrorWidget(message: error!, onRetry: onRetry);
    }
    if (rows.isEmpty) {
      return ReportEmptyState(message: emptyMessage);
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool tablet = constraints.maxWidth >= AppBreakpoints.medium;
        if (tablet) {
          return _table(context);
        }
        return _cards(context);
      },
    );
  }

  Widget _cards(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        if (index == rows.length) {
          return _footer(context);
        }
        final Object row = rows[index];
        if (cardBuilder != null) {
          return cardBuilder!(context, row);
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final ReportColumn column in columns) ...<Widget>[
                Text(
                  column.label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                column.cell?.call(context, row) ?? Text(column.value(row)),
                if (column != columns.last)
                  const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _table(BuildContext context) {
    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: <DataColumn>[
              for (final ReportColumn column in columns)
                DataColumn(label: Text(column.label)),
            ],
            rows: <DataRow>[
              for (final Object row in rows)
                DataRow(
                  cells: <DataCell>[
                    for (final ReportColumn column in columns)
                      DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(minWidth: column.minWidth),
                          child: column.cell?.call(context, row) ??
                              Text(column.value(row)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        _footer(context),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    if (error != null && rows.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: <Widget>[
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Retry',
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: AppLoader(),
      );
    }
    if (hasMore && onLoadMore != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: AppButton(
          label: 'Load more',
          variant: AppButtonVariant.outlined,
          expand: false,
          onPressed: onLoadMore,
        ),
      );
    }
    return const SizedBox(height: AppSpacing.md);
  }
}
