import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:flutter_base/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_base/features/notifications/domain/services/fcm_gateway.dart';
import 'package:flutter_base/features/notifications/domain/services/firebase_fcm_gateway.dart';
import 'package:flutter_base/features/notifications/domain/services/firebase_notification_service.dart';
import 'package:flutter_base/features/notifications/domain/services/notification_navigation_service.dart';
import 'package:flutter_base/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((Ref ref) {
  return NotificationRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((
  Ref ref,
) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDataSourceProvider),
  );
});

final getNotificationsUseCaseProvider = Provider<GetNotifications>((Ref ref) {
  return GetNotifications(ref.watch(notificationRepositoryProvider));
});

final getNotificationDetailUseCaseProvider = Provider<GetNotificationDetail>((
  Ref ref,
) {
  return GetNotificationDetail(ref.watch(notificationRepositoryProvider));
});

final getUnreadNotificationCountUseCaseProvider =
    Provider<GetUnreadNotificationCount>((Ref ref) {
  return GetUnreadNotificationCount(ref.watch(notificationRepositoryProvider));
});

final markNotificationAsReadUseCaseProvider =
    Provider<MarkNotificationAsRead>((Ref ref) {
  return MarkNotificationAsRead(ref.watch(notificationRepositoryProvider));
});

final markAllNotificationsAsReadUseCaseProvider =
    Provider<MarkAllNotificationsAsRead>((Ref ref) {
  return MarkAllNotificationsAsRead(ref.watch(notificationRepositoryProvider));
});

final registerDeviceTokenUseCaseProvider = Provider<RegisterDeviceToken>((
  Ref ref,
) {
  return RegisterDeviceToken(ref.watch(notificationRepositoryProvider));
});

final updateDeviceTokenUseCaseProvider = Provider<UpdateDeviceToken>((Ref ref) {
  return UpdateDeviceToken(ref.watch(notificationRepositoryProvider));
});

final removeDeviceTokenUseCaseProvider = Provider<RemoveDeviceToken>((Ref ref) {
  return RemoveDeviceToken(ref.watch(notificationRepositoryProvider));
});

final notificationNavigationServiceProvider =
    Provider<NotificationNavigationService>((Ref ref) {
  return const NotificationNavigationService();
});

final fcmGatewayProvider = Provider<FcmGateway>((Ref ref) {
  return FirebaseFcmGateway();
});

final firebaseNotificationServiceProvider =
    Provider<FirebaseNotificationService>((Ref ref) {
  final FirebaseNotificationService service =
      FirebaseNotificationService(ref.watch(fcmGatewayProvider));
  ref.onDispose(service.dispose);
  return service;
});

final notificationDetailProvider =
    FutureProvider.autoDispose.family<AppNotification, String>((
  Ref ref,
  String id,
) {
  ref.watch(authControllerProvider);
  return ref.watch(getNotificationDetailUseCaseProvider)(id);
});
