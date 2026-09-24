enum NotificationType {
  taskAssigned,
  taskDueChanged,
  taskStatusChanged,
  taskCommentAdded,
  taskMessageAdded,
  chatMention,
  reviewRequired,
  memberJoined,
  joinRequestApproved,
  joinRequestRejected,
}

extension NotificationTypeMapper on NotificationType {
  String get value {
    return switch (this) {
      NotificationType.taskAssigned => 'task_assigned',
      NotificationType.taskDueChanged => 'task_due_changed',
      NotificationType.taskStatusChanged => 'task_status_changed',
      NotificationType.taskCommentAdded => 'task_comment_added',
      NotificationType.taskMessageAdded => 'task_message_added',
      NotificationType.chatMention => 'chat_mention',
      NotificationType.reviewRequired => 'review_required',
      NotificationType.memberJoined => 'member_joined',
      NotificationType.joinRequestApproved => 'join_request_approved',
      NotificationType.joinRequestRejected => 'join_request_rejected',
    };
  }

  static NotificationType fromValue(String? value) {
    return switch (value) {
      'task_due_changed' => NotificationType.taskDueChanged,
      'task_status_changed' => NotificationType.taskStatusChanged,
      'task_comment_added' => NotificationType.taskCommentAdded,
      'task_message_added' => NotificationType.taskMessageAdded,
      'chat_mention' => NotificationType.chatMention,
      'review_required' => NotificationType.reviewRequired,
      'member_joined' => NotificationType.memberJoined,
      'join_request_approved' => NotificationType.joinRequestApproved,
      'join_request_rejected' => NotificationType.joinRequestRejected,
      _ => NotificationType.taskAssigned,
    };
  }
}

enum NotificationEntityType { workspace, project, task }

extension NotificationEntityTypeMapper on NotificationEntityType {
  String get value {
    return switch (this) {
      NotificationEntityType.workspace => 'workspace',
      NotificationEntityType.project => 'project',
      NotificationEntityType.task => 'task',
    };
  }

  static NotificationEntityType fromValue(String? value) {
    return switch (value) {
      'workspace' => NotificationEntityType.workspace,
      'project' => NotificationEntityType.project,
      _ => NotificationEntityType.task,
    };
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationEntityType entityType;
  final String entityId;
  final bool isRead;
  final DateTime? createdAt;
}
