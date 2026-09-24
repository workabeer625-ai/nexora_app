import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/app_notification.dart';

final class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.entityType,
    required super.entityId,
    required super.isRead,
    super.titleAr,
    super.bodyAr,
    super.createdAt,
  });

  factory AppNotificationModel.fromEntity(AppNotification notification) {
    return AppNotificationModel(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      titleAr: notification.titleAr,
      bodyAr: notification.bodyAr,
      entityType: notification.entityType,
      entityId: notification.entityId,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );
  }

  factory AppNotificationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return AppNotificationModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      userId: FirestoreValueParsers.string(data['user_id']),
      type: NotificationTypeMapper.fromValue(
        FirestoreValueParsers.string(data['type']),
      ),
      title: FirestoreValueParsers.string(data['title']),
      body: FirestoreValueParsers.string(data['body']),
      titleAr: _nullableString(data['title_ar']),
      bodyAr: _nullableString(data['body_ar']),
      entityType: NotificationEntityTypeMapper.fromValue(
        FirestoreValueParsers.string(data['entity_type']),
      ),
      entityId: FirestoreValueParsers.string(data['entity_id']),
      isRead: FirestoreValueParsers.boolean(data['is_read'], fallback: false),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
    );
  }
}

String? _nullableString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}
