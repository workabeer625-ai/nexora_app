import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/app_notification_model.dart';

final class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestoreService.collection(
      FirestorePaths.userNotifications(userId),
    );
  }

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _collection(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotificationModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Future<void> createNotification(AppNotification notification) async {
    final collection = _collection(notification.userId);
    final doc = notification.id.isEmpty
        ? collection.doc()
        : collection.doc(notification.id);
    final model = AppNotificationModel.fromEntity(
      AppNotification(
        id: doc.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        entityType: notification.entityType,
        entityId: notification.entityId,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
      ),
    );

    await doc.set({
      'id': model.id,
      'user_id': model.userId,
      'type': model.type.value,
      'title': model.title,
      'body': model.body,
      'entity_type': model.entityType.value,
      'entity_id': model.entityId,
      'is_read': model.isRead,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) {
    return _collection(userId).doc(notificationId).update({'is_read': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _collection(
      userId,
    ).where('is_read', isEqualTo: false).get();
    final batch = _firestoreService.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }

    await batch.commit();
  }
}
