import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// Backend default role catalogs for test fixtures only.
/// Production authorization never uses these lists as a matrix.
const List<String> kEmployeePermissions = <String>[
  Permissions.employeesView,
  Permissions.attendanceView,
  Permissions.attendanceCheckIn,
  Permissions.attendanceCheckOut,
  Permissions.leaveView,
  Permissions.leaveCreate,
  Permissions.devicesView,
  Permissions.documentsView,
  Permissions.documentsCreate,
  Permissions.documentsDownload,
  Permissions.notificationsView,
  Permissions.notificationsMarkRead,
  Permissions.dashboardEmployeeView,
];

const List<String> kManagerPermissions = <String>[
  Permissions.employeesView,
  Permissions.employeesUpdate,
  Permissions.attendanceView,
  Permissions.attendanceManage,
  Permissions.leaveView,
  Permissions.leaveApprove,
  Permissions.leaveReject,
  Permissions.leaveManage,
  Permissions.devicesView,
  Permissions.devicesAssign,
  Permissions.devicesReturn,
  Permissions.documentsView,
  Permissions.documentsCreate,
  Permissions.documentsUpdate,
  Permissions.documentsDownload,
  Permissions.notificationsView,
  Permissions.notificationsMarkRead,
  Permissions.dashboardManagerView,
  Permissions.dashboardEmployeeView,
  Permissions.reportsView,
];

const String kSampleCompanyId = '11111111-1111-1111-1111-111111111111';

Authorization authOf(User user) => Authorization.fromUser(user);

Authorization anonymousAuth() => const Authorization.anonymous();
