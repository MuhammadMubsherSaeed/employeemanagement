import 'package:flutter/material.dart';
import 'package:flutter_base/core/config/app_config_provider.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
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
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_opener.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_action_controller.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_reject_sheet.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveRequestDetailsScreen extends ConsumerWidget {
  const LeaveRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.approvalMode = false,
  });

  final String requestId;
  final bool approvalMode;

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Approve leave',
      message: 'Approve this leave request?',
      confirmLabel: 'Approve',
    );
    if (confirmed != true) {
      return;
    }
    final LeaveRequest? result =
        await ref.read(leaveActionControllerProvider.notifier).approve(requestId);
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      context.showSnack('Leave request approved.');
    } else {
      _showActionError(context, ref);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final String? reason = await showLeaveRejectSheet(context);
    if (reason == null || !context.mounted) {
      return;
    }
    final LeaveRequest? result =
        await ref.read(leaveActionControllerProvider.notifier).reject(
              id: requestId,
              rejectionReason: reason,
            );
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      context.showSnack('Leave request rejected.');
    } else {
      _showActionError(context, ref);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Cancel leave request',
      message: 'Are you sure you want to cancel this leave request?',
      confirmLabel: 'Cancel request',
      cancelLabel: 'Keep',
    );
    if (confirmed != true) {
      return;
    }
    final LeaveRequest? result =
        await ref.read(leaveActionControllerProvider.notifier).cancel(requestId);
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      context.showSnack('Leave request cancelled.');
    } else {
      _showActionError(context, ref);
    }
  }

  void _showActionError(BuildContext context, WidgetRef ref) {
    final String? error = ref.read(leaveActionControllerProvider).error;
    if (error != null) {
      context.showSnack(error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);
    final LeaveAccess access = LeaveAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );
    final LeaveActionState action = ref.watch(leaveActionControllerProvider);
    final AsyncValue<LeaveRequest> async =
        ref.watch(leaveRequestDetailProvider(requestId));
    final String apiBaseUrl = ref.watch(appConfigProvider).apiBaseUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(approvalMode ? 'Review leave request' : 'Leave details'),
      ),
      body: async.when(
        loading: () => const AppLoader(message: 'Loading leave request…'),
        error: (Object error, _) => AppErrorWidget(
          message: LeaveErrorMapper.message(error),
          onRetry: () => ref.invalidate(leaveRequestDetailProvider(requestId)),
        ),
        data: (LeaveRequest request) {
          final String? attachmentUrl =
              resolveLeaveAttachmentUrl(request.attachment, apiBaseUrl);
          final bool showApprove =
              access.canApprove && request.isPending;
          final bool showReject = access.canReject && request.isPending;
          final bool showCancel = request.canAttemptCancel &&
              (access.canCreate || access.canManage || access.canApprove);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaveRequestDetailProvider(requestId));
              await ref.read(leaveRequestDetailProvider(requestId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screen,
              children: <Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              request.leaveType?.name ?? 'Leave',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          LeaveStatusBadge(status: request.status),
                        ],
                      ),
                      if (access.canViewTeam && request.employee != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          request.employee!.fullName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          request.employee!.employeeCode,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _row(
                        context,
                        'Dates',
                        AppDateFormatter.dateRange(
                          request.startDate,
                          request.endDate,
                        ),
                      ),
                      _row(
                        context,
                        'Total days',
                        leaveDaysLabel(request.totalDays),
                      ),
                      if (request.reason.isNotEmpty)
                        _row(context, 'Reason', request.reason),
                      if (request.createdAt != null)
                        _row(
                          context,
                          'Created',
                          AppDateFormatter.dateTime(request.createdAt!.toLocal()),
                        ),
                      if (request.approvedAt != null)
                        _row(
                          context,
                          'Approved at',
                          AppDateFormatter.dateTime(
                            request.approvedAt!.toLocal(),
                          ),
                        ),
                      if (request.approvedBy != null)
                        _row(context, 'Approved by', '${request.approvedBy}'),
                      if (request.rejectionReason.isNotEmpty)
                        _row(
                          context,
                          'Rejection reason',
                          request.rejectionReason,
                        ),
                    ],
                  ),
                ),
                if (attachmentUrl != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Open attachment',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final bool ok = await openLeaveAttachment(attachmentUrl);
                      if (!context.mounted) {
                        return;
                      }
                      if (!ok) {
                        context.showSnack('Unable to open the attachment.');
                      }
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (showApprove)
                  AppButton(
                    label: 'Approve',
                    isLoading: action.isApproving,
                    onPressed: action.isBusy ? null : () => _approve(context, ref),
                  ),
                if (showReject) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Reject',
                    variant: AppButtonVariant.outlined,
                    isLoading: action.isRejecting,
                    onPressed: action.isBusy ? null : () => _reject(context, ref),
                  ),
                ],
                if (showCancel) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Cancel request',
                    variant: AppButtonVariant.text,
                    isLoading: action.isCancelling,
                    onPressed: action.isBusy ? null : () => _cancel(context, ref),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return LeaveRequestDetailsScreen(
      requestId: requestId,
      approvalMode: true,
    );
  }
}
