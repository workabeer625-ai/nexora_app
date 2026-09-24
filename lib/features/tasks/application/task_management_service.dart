import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/validators/input_validators.dart';
import '../../notifications/domain/entities/app_notification.dart';
import '../../notifications/domain/repositories/notification_repository.dart';
import '../../workspaces/domain/repositories/workspace_repository.dart';
import '../domain/entities/task_item.dart';
import '../domain/repositories/task_repository.dart';

final class TaskManagementService {
  TaskManagementService({
    required TaskRepository taskRepository,
    required WorkspaceRepository workspaceRepository,
    required NotificationRepository notificationRepository,
  }) : _taskRepository = taskRepository,
       _workspaceRepository = workspaceRepository,
       _notificationRepository = notificationRepository;

  final TaskRepository _taskRepository;
  final WorkspaceRepository _workspaceRepository;
  final NotificationRepository _notificationRepository;

  Future<String> createTask({
    required String actorId,
    required String workspaceId,
    required String projectId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    required String? assignedTo,
    required DateTime? startDate,
    required DateTime? dueDate,
    required int progress,
    required String? blockedReason,
    required ReviewStatus reviewStatus,
  }) async {
    final normalized = await _normalizeTaskFields(
      workspaceId: workspaceId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignedTo: assignedTo,
      startDate: startDate,
      dueDate: dueDate,
      progress: progress,
      blockedReason: blockedReason,
      reviewStatus: reviewStatus,
    );

    final taskId = await _taskRepository.createTask(
      workspaceId: workspaceId,
      projectId: projectId,
      title: normalized.title,
      description: normalized.description,
      status: normalized.status,
      priority: normalized.priority,
      assignedTo: normalized.assignedTo,
      createdBy: actorId,
      startDate: normalized.startDate,
      dueDate: normalized.dueDate,
      progress: normalized.progress,
      isBlocked: normalized.isBlocked,
      blockedReason: normalized.blockedReason,
      reviewStatus: normalized.reviewStatus,
      completedAt: normalized.completedAt,
    );

    if (normalized.assignedTo != null && normalized.assignedTo != actorId) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: normalized.assignedTo!,
          type: NotificationType.taskAssigned,
          title: 'Task assigned',
          body: 'You were assigned to ${normalized.title}.',
          entityType: NotificationEntityType.task,
          entityId: taskId,
          isRead: false,
        ),
      );
    }

    return taskId;
  }

  Future<void> updateTask({
    required String actorId,
    required TaskItem currentTask,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    required String? assignedTo,
    required DateTime? startDate,
    required DateTime? dueDate,
    required int progress,
    required String? blockedReason,
    required ReviewStatus reviewStatus,
  }) async {
    final normalized = await _normalizeTaskFields(
      workspaceId: currentTask.workspaceId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assignedTo: assignedTo,
      startDate: startDate,
      dueDate: dueDate,
      progress: progress,
      blockedReason: blockedReason,
      reviewStatus: reviewStatus,
    );

    await _taskRepository.updateTask(
      workspaceId: currentTask.workspaceId,
      projectId: currentTask.projectId,
      taskId: currentTask.id,
      changes: {
        'title': normalized.title,
        'description': normalized.description,
        'status': normalized.status.value,
        'priority': normalized.priority.value,
        'assigned_to': normalized.assignedTo,
        'start_date': normalized.startDate == null
            ? null
            : Timestamp.fromDate(normalized.startDate!),
        'due_date': normalized.dueDate == null
            ? null
            : Timestamp.fromDate(normalized.dueDate!),
        'progress': normalized.progress,
        'is_blocked': normalized.isBlocked,
        'blocked_reason': normalized.blockedReason,
        'review_status': normalized.reviewStatus.value,
        'completed_at': normalized.completedAt == null
            ? null
            : Timestamp.fromDate(normalized.completedAt!),
      },
    );

    if (currentTask.assignedTo != normalized.assignedTo &&
        normalized.assignedTo != null &&
        normalized.assignedTo != actorId) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: normalized.assignedTo!,
          type: NotificationType.taskAssigned,
          title: 'Task assigned',
          body: 'You were assigned to ${normalized.title}.',
          entityType: NotificationEntityType.task,
          entityId: currentTask.id,
          isRead: false,
        ),
      );
    }

    if (currentTask.dueDate != normalized.dueDate &&
        normalized.assignedTo != null &&
        normalized.assignedTo != actorId) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: normalized.assignedTo!,
          type: NotificationType.taskDueChanged,
          title: 'Due date updated',
          body: 'The due date for ${normalized.title} was updated.',
          entityType: NotificationEntityType.task,
          entityId: currentTask.id,
          isRead: false,
        ),
      );
    }

    if (currentTask.status != normalized.status) {
      final targets = <String>{
        if (normalized.assignedTo != null) normalized.assignedTo!,
        currentTask.createdBy,
      }..remove(actorId);

      for (final userId in targets) {
        await _notificationRepository.createNotification(
          AppNotification(
            id: '',
            userId: userId,
            type: NotificationType.taskStatusChanged,
            title: 'Task status changed',
            body: '${normalized.title} is now ${normalized.status.label}.',
            entityType: NotificationEntityType.task,
            entityId: currentTask.id,
            isRead: false,
          ),
        );
      }
    }

    if (normalized.status == TaskStatus.inReview &&
        currentTask.status != TaskStatus.inReview) {
      final reviewerId = currentTask.createdBy == actorId
          ? normalized.assignedTo
          : currentTask.createdBy;

      if (reviewerId != null && reviewerId != actorId) {
        await _notificationRepository.createNotification(
          AppNotification(
            id: '',
            userId: reviewerId,
            type: NotificationType.reviewRequired,
            title: 'Review required',
            body: '${normalized.title} moved to review.',
            entityType: NotificationEntityType.task,
            entityId: currentTask.id,
            isRead: false,
          ),
        );
      }
    }
  }

  Future<void> addComment({
    required String workspaceId,
    required String projectId,
    required TaskItem task,
    required String authorId,
    required String content,
  }) async {
    final normalizedContent = InputValidators.validateRequiredText(
      content,
      fieldName: 'Comment',
      minLength: 1,
      maxLength: 1200,
    );

    await _taskRepository.addComment(
      workspaceId: workspaceId,
      projectId: projectId,
      taskId: task.id,
      authorId: authorId,
      content: normalizedContent,
    );

    final targets = <String>{
      task.createdBy,
      if (task.assignedTo != null) task.assignedTo!,
    }..remove(authorId);

    for (final userId in targets) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          userId: userId,
          type: NotificationType.taskCommentAdded,
          title: 'New task comment',
          body: 'A new comment was added to ${task.title}.',
          entityType: NotificationEntityType.task,
          entityId: task.id,
          isRead: false,
        ),
      );
    }
  }

  Future<void> _validateAssignee(String workspaceId, String? assignedTo) async {
    if (assignedTo == null || assignedTo.trim().isEmpty) {
      return;
    }

    final isMember = await _workspaceRepository.isActiveMember(
      workspaceId,
      assignedTo.trim(),
    );
    if (!isMember) {
      throw const ValidationException(
        'Assigned user must be an active workspace member.',
      );
    }
  }

  Future<_NormalizedTaskFields> _normalizeTaskFields({
    required String workspaceId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    required String? assignedTo,
    required DateTime? startDate,
    required DateTime? dueDate,
    required int progress,
    required String? blockedReason,
    required ReviewStatus reviewStatus,
  }) async {
    final normalizedTitle = InputValidators.validateRequiredText(
      title,
      fieldName: 'Task title',
      minLength: 2,
      maxLength: 120,
    );
    final normalizedDescription = description.trim();
    final normalizedAssignee = assignedTo?.trim().isEmpty == true
        ? null
        : assignedTo?.trim();
    final normalizedProgress = InputValidators.validateProgress(progress);
    InputValidators.validateDateRange(startDate, dueDate);
    await _validateAssignee(workspaceId, normalizedAssignee);

    final normalizedBlockedReason = blockedReason?.trim().isEmpty == true
        ? null
        : blockedReason?.trim();

    final isBlocked = status == TaskStatus.blocked;
    if (isBlocked && normalizedBlockedReason == null) {
      throw const ValidationException(
        'Blocked tasks require a blocked reason.',
      );
    }

    var normalizedReviewStatus = reviewStatus;
    if (status == TaskStatus.inReview && reviewStatus == ReviewStatus.none) {
      normalizedReviewStatus = ReviewStatus.pending;
    }

    final completedAt = status == TaskStatus.done ? DateTime.now() : null;
    final normalizedCompletedProgress = status == TaskStatus.done
        ? 100
        : normalizedProgress;

    return _NormalizedTaskFields(
      title: normalizedTitle,
      description: normalizedDescription,
      status: status,
      priority: priority,
      assignedTo: normalizedAssignee,
      startDate: startDate,
      dueDate: dueDate,
      progress: normalizedCompletedProgress,
      isBlocked: isBlocked,
      blockedReason: isBlocked ? normalizedBlockedReason : null,
      reviewStatus: normalizedReviewStatus,
      completedAt: completedAt,
    );
  }
}

final class _NormalizedTaskFields {
  const _NormalizedTaskFields({
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.startDate,
    required this.dueDate,
    required this.progress,
    required this.isBlocked,
    required this.blockedReason,
    required this.reviewStatus,
    required this.completedAt,
  });

  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assignedTo;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int progress;
  final bool isBlocked;
  final String? blockedReason;
  final ReviewStatus reviewStatus;
  final DateTime? completedAt;
}
