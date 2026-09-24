enum ChatMessageType { text }

extension ChatMessageTypeMapper on ChatMessageType {
  String get value {
    return switch (this) {
      ChatMessageType.text => 'text',
    };
  }

  static ChatMessageType fromValue(String? value) {
    return switch (value) {
      'text' => ChatMessageType.text,
      _ => ChatMessageType.text,
    };
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.isEdited,
    required this.isDeleted,
    this.senderAvatar,
    this.createdAt,
    this.updatedAt,
    this.mentions = const <String>[],
    this.replyToMessageId,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final ChatMessageType type;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final List<String> mentions;
  final String? replyToMessageId;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    ChatMessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    List<String>? mentions,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      mentions: mentions ?? this.mentions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }
}
