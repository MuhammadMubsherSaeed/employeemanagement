import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_requests_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_filter_sheet.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_request_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeaveRequestsScreen extends ConsumerWidget {
  const LeaveRequestsScreen({
    super.key,
    this.kind = LeaveListKind.all,
    this.title = 'Leave requests',
  });

  final LeaveListKind kind;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LeaveAccess access = LeaveAccess(
      ref.watch(authorizationProvider),
    );
    final LeaveRequestsState list =
        ref.watch(leaveRequestsControllerProvider(kind));
    final int filters = list.query.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            tooltip: filters == 0 ? 'Filters' : 'Filters ($filters)',
            onPressed: () => _openFilters(context, ref, access),
            icon: Badge(
              isLabelVisible: filters > 0,
              label: Text('$filters'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: LeaveRequestListView(
        kind: kind,
        showEmployee: access.canViewTeam,
        onOpen: (LeaveRequest request) {
          context.push(
            access.canApprove && request.isPending && kind == LeaveListKind.pendingApproval
                ? AppRoutes.leaveApproval(request.id)
                : AppRoutes.leaveRequest(request.id),
          );
        },
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    LeaveAccess access,
  ) async {
    final LeaveRequestsState list =
        ref.read(leaveRequestsControllerProvider(kind));
    List<LeaveType> types = const <LeaveType>[];
    try {
      types = await ref.read(leaveTypesProvider.future);
    } catch (_) {}
    if (!context.mounted) {
      return;
    }
    final LeaveRequestQuery? next = await showLeaveFilterSheet(
      context: context,
      current: list.query,
      leaveTypes: types,
      canFilterByEmployee: access.canFilterByEmployee,
    );
    if (next == null) {
      return;
    }
    await ref
        .read(leaveRequestsControllerProvider(kind).notifier)
        .applyFilters(next);
  }
}

class LeaveHistoryScreen extends StatelessWidget {
  const LeaveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeaveRequestsScreen(
      kind: LeaveListKind.history,
      title: 'Leave history',
    );
  }
}
