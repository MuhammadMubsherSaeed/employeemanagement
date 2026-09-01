import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/leaves/data/datasources/leave_remote_datasource.dart';
import 'package:flutter_base/features/leaves/data/repositories/leave_repository_impl.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/repositories/leave_repository.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_picker.dart';
import 'package:flutter_base/features/leaves/domain/usecases/leave_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaveRemoteDataSourceProvider = Provider<LeaveRemoteDataSource>((Ref ref) {
  return LeaveRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final leaveRepositoryProvider = Provider<LeaveRepository>((Ref ref) {
  return LeaveRepositoryImpl(ref.watch(leaveRemoteDataSourceProvider));
});

final leaveAttachmentPickerProvider = Provider<LeaveAttachmentPicker>((Ref ref) {
  return FilePickerLeaveAttachmentPicker();
});

final getLeaveTypesProvider = Provider<GetLeaveTypes>((Ref ref) {
  return GetLeaveTypes(ref.watch(leaveRepositoryProvider));
});

final getLeaveTypeUseCaseProvider = Provider<GetLeaveType>((Ref ref) {
  return GetLeaveType(ref.watch(leaveRepositoryProvider));
});

final getLeaveBalancesUseCaseProvider = Provider<GetLeaveBalances>((Ref ref) {
  return GetLeaveBalances(ref.watch(leaveRepositoryProvider));
});

final getLeaveRequestsUseCaseProvider = Provider<GetLeaveRequests>((Ref ref) {
  return GetLeaveRequests(ref.watch(leaveRepositoryProvider));
});

final getLeaveRequestDetailsUseCaseProvider =
    Provider<GetLeaveRequestDetails>((Ref ref) {
  return GetLeaveRequestDetails(ref.watch(leaveRepositoryProvider));
});

final createLeaveRequestUseCaseProvider =
    Provider<CreateLeaveRequest>((Ref ref) {
  return CreateLeaveRequest(ref.watch(leaveRepositoryProvider));
});

final approveLeaveRequestUseCaseProvider =
    Provider<ApproveLeaveRequest>((Ref ref) {
  return ApproveLeaveRequest(ref.watch(leaveRepositoryProvider));
});

final rejectLeaveRequestUseCaseProvider =
    Provider<RejectLeaveRequest>((Ref ref) {
  return RejectLeaveRequest(ref.watch(leaveRepositoryProvider));
});

final cancelLeaveRequestUseCaseProvider =
    Provider<CancelLeaveRequest>((Ref ref) {
  return CancelLeaveRequest(ref.watch(leaveRepositoryProvider));
});

final downloadLeaveAttachmentUseCaseProvider =
    Provider<DownloadLeaveAttachment>((Ref ref) {
  return DownloadLeaveAttachment(ref.watch(leaveRepositoryProvider));
});

final createLeaveTypeUseCaseProvider = Provider<CreateLeaveType>((Ref ref) {
  return CreateLeaveType(ref.watch(leaveRepositoryProvider));
});

final updateLeaveTypeUseCaseProvider = Provider<UpdateLeaveType>((Ref ref) {
  return UpdateLeaveType(ref.watch(leaveRepositoryProvider));
});

final allocateLeaveBalanceUseCaseProvider =
    Provider<AllocateLeaveBalance>((Ref ref) {
  return AllocateLeaveBalance(ref.watch(leaveRepositoryProvider));
});

final leaveTypesProvider =
    FutureProvider.autoDispose<List<LeaveType>>((Ref ref) async {
  ref.watch(authControllerProvider);
  final LeavePage<LeaveType> page =
      await ref.watch(getLeaveTypesProvider)(activeOnly: false);
  return page.results;
});

final activeLeaveTypesProvider =
    FutureProvider.autoDispose<List<LeaveType>>((Ref ref) async {
  ref.watch(authControllerProvider);
  final LeavePage<LeaveType> page =
      await ref.watch(getLeaveTypesProvider)(activeOnly: true);
  return page.results;
});

final leaveBalancesProvider =
    FutureProvider.autoDispose<List<LeaveBalance>>((Ref ref) async {
  ref.watch(authControllerProvider);
  final LeavePage<LeaveBalance> page =
      await ref.watch(getLeaveBalancesUseCaseProvider)();
  return page.results;
});

final leaveTypeDetailProvider =
    FutureProvider.autoDispose.family<LeaveType, String>((Ref ref, String id) {
  ref.watch(authControllerProvider);
  return ref.watch(getLeaveTypeUseCaseProvider)(id);
});

final leaveRequestDetailProvider =
    FutureProvider.autoDispose.family<LeaveRequest, String>(
  (Ref ref, String id) {
    ref.watch(authControllerProvider);
    return ref.watch(getLeaveRequestDetailsUseCaseProvider)(id);
  },
);
