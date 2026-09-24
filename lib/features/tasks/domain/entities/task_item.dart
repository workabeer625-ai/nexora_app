enum TaskStatus { todo, inProgress, blocked, inReview, done }

extension TaskStatusMapper on TaskStatus {
  String get value {
    return switch (this) {
      TaskStatus.todo => 'todo',
      TaskStatus.inProgress => 'in_progress',
      TaskStatus.blocked => 'blocked',
      TaskStatus.inReview => 'in_review',
      TaskStatus.done => 'done',
    };
  }

  String get label {
    return switch (this) {
      TaskStatus.todo => 'To do',
      TaskStatus.inProgress => 'In progress',
      TaskStatus.blocked => 'Blocked',
      TaskStatus.inReview => 'In review',
      TaskStatus.done => 'Done',
    };
  }

  static TaskStatus fromValue(String? value) {
    return switch (value) {
      'in_progress' => TaskStatus.inProgress,
      'blocked' => TaskStatus.blocked,
      'in_review' => TaskStatus.inReview,
      'done' => TaskStatus.done,
      _ => TaskStatus.todo,
    };
  }
}

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityMapper on TaskPriority {
  String get value {
    return switch (this) {
      TaskPriority.low => 'low',
      TaskPriority.medium => 'medium',
      TaskPriority.high => 'high',
      TaskPriority.urgent => 'urgent',
    };
  }

  String get label {
    return switch (this) {
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Medium',
      TaskPriority.high => 'High',
      TaskPriority.urgent => 'Urgent',
    };
  }

  static TaskPriority fromValue(String? value) {
    return switch (value) {
      'low' => TaskPriority.low,
      'high' => TaskPriority.high,
      'urgent' => TaskPriority.urgent,
      _ => TaskPriority.medium,
    };
  }
}

enum ReviewStatus { none, pending, approved, rejected }

extension ReviewStatusMapper on ReviewStatus {
  String get value {
    return switch (this) {
      ReviewStatus.none => 'none',
      ReviewStatus.pending => 'pending',
      ReviewStatus.approved => 'approved',
      ReviewStatus.rejected => 'rejected',
    };
  }

  String get label {
    return switch (this) {
      ReviewStatus.none => 'None',
      ReviewStatus.pending => 'Pending',
      ReviewStatus.approved => 'Approved',
      ReviewStatus.rejected => 'Rejected',
    };
  }

  static ReviewStatus fromValue(String? value) {
    return switch (value) {
      'pending' => ReviewStatus.pending,
      'approved' => ReviewStatus.approved,
      'rejected' => ReviewStatus.rejected,
      _ => ReviewStatus.none,
    };
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.workspaceId,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.progress,
    required this.isBlocked,
    required this.reviewStatus,
    required this.isArchived,
    this.assignedTo,
    this.startDate,
    this.dueDate,
    this.blockedReason,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String workspaceId;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assignedTo;
  final String createdBy;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int progress;
  final bool isBlocked;
  final String? blockedReason;
  final ReviewStatus reviewStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final bool isArchived;
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.content,
    required this.isEdited,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String authorId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
}
