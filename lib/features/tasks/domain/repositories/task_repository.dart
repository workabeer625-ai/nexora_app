import '../entities/task_item.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> watchTasks(String workspaceId, String projectId);

  Stream<List<TaskItem>> watchWorkspaceTasks(String workspaceId);

  Stream<List<TaskItem>> watchAssignedWorkspaceTasks(
    String workspaceId,
    String userId,
  );

  Stream<TaskItem?> watchTask(
    String workspaceId,
    String projectId,
    String taskId,
  );

  Future<String> createTask({
    required String workspaceId,
    required String projectId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    required String? assignedTo,
    required String createdBy,
    required DateTime? startDate,
    required DateTime? dueDate,
    required int progress,
    required bool isBlocked,
    required String? blockedReason,
    required ReviewStatus reviewStatus,
    required DateTime? completedAt,
  });

  Future<void> updateTask({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required Map<String, dynamic> changes,
  });

  Stream<List<TaskComment>> watchComments(
    String workspaceId,
    String projectId,
    String taskId,
  );

  Future<void> addComment({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required String authorId,
    required String content,
  });
}
