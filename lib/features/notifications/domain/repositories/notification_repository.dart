import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  Future<void> createNotification(AppNotification notification);

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  });

  Future<void> markAllAsRead(String userId);
}
