import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/chat_message.dart';

final class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.type,
    required super.isEdited,
    required super.isDeleted,
    super.senderAvatar,
    super.createdAt,
    super.updatedAt,
    super.mentions,
    super.replyToMessageId,
  });

  factory ChatMessageModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final senderAvatar = FirestoreValueParsers.string(data['sender_avatar']);
    final replyToMessageId = FirestoreValueParsers.string(
      data['reply_to_message_id'],
    );

    return ChatMessageModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      senderId: FirestoreValueParsers.string(data['sender_id']),
      senderName: FirestoreValueParsers.string(
        data['sender_name'],
        fallback: 'Unknown',
      ),
      senderAvatar: senderAvatar.isEmpty ? null : senderAvatar,
      content: FirestoreValueParsers.string(data['content']),
      type: ChatMessageTypeMapper.fromValue(
        FirestoreValueParsers.string(data['type'], fallback: 'text'),
      ),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
      isEdited: FirestoreValueParsers.boolean(data['is_edited']),
      isDeleted: FirestoreValueParsers.boolean(data['is_deleted']),
      mentions: FirestoreValueParsers.stringList(data['mentions']),
      replyToMessageId: replyToMessageId.isEmpty ? null : replyToMessageId,
    );
  }

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderAvatar: entity.senderAvatar,
      content: entity.content,
      type: entity.type,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isEdited: entity.isEdited,
      isDeleted: entity.isDeleted,
      mentions: entity.mentions,
      replyToMessageId: entity.replyToMessageId,
    );
  }

  Map<String, dynamic> toCreateFirestore() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type.value,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_edited': false,
      'is_deleted': false,
      'mentions': mentions,
      'reply_to_message_id': replyToMessageId,
    };
  }
}
