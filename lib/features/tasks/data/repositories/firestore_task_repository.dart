import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_comment_model.dart';
import '../models/task_item_model.dart';

final class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> _tasks(
    String workspaceId,
    String projectId,
  ) {
    return _firestoreService.collection(
      FirestorePaths.projectTasks(workspaceId, projectId),
    );
  }

  CollectionReference<Map<String, dynamic>> _projects(String workspaceId) {
    return _firestoreService.collection(
      FirestorePaths.workspaceProjects(workspaceId),
    );
  }

  DocumentReference<Map<String, dynamic>> _taskDoc(
    String workspaceId,
    String projectId,
    String taskId,
  ) {
    return _firestoreService.document(
      FirestorePaths.task(workspaceId, projectId, taskId),
    );
  }

  CollectionReference<Map<String, dynamic>> _comments(
    String workspaceId,
    String projectId,
    String taskId,
  ) {
    return _firestoreService.collection(
      FirestorePaths.taskComments(workspaceId, projectId, taskId),
    );
  }

  @override
  Stream<List<TaskItem>> watchTasks(String workspaceId, String projectId) {
    return _tasks(workspaceId, projectId)
        .where('is_archived', isEqualTo: false)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TaskItemModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<TaskItem>> watchWorkspaceTasks(String workspaceId) {
    return _watchTasksAcrossWorkspace(workspaceId: workspaceId);
  }

  @override
  Stream<List<TaskItem>> watchAssignedWorkspaceTasks(
    String workspaceId,
    String userId,
  ) {
    return _watchTasksAcrossWorkspace(
      workspaceId: workspaceId,
      assignedTo: userId,
    );
  }

  @override
  Stream<TaskItem?> watchTask(
    String workspaceId,
    String projectId,
    String taskId,
  ) {
    return _taskDoc(workspaceId, projectId, taskId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return TaskItemModel.fromSnapshot(snapshot);
    });
  }

  @override
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
  }) async {
    final taskDoc = _tasks(workspaceId, projectId).doc();

    await taskDoc.set({
      'id': taskDoc.id,
      'workspace_id': workspaceId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'start_date': startDate == null ? null : Timestamp.fromDate(startDate),
      'due_date': dueDate == null ? null : Timestamp.fromDate(dueDate),
      'progress': progress,
      'is_blocked': isBlocked,
      'blocked_reason': blockedReason,
      'review_status': reviewStatus.value,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'completed_at': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt),
      'is_archived': false,
    });

    return taskDoc.id;
  }

  @override
  Future<void> updateTask({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required Map<String, dynamic> changes,
  }) {
    return _taskDoc(
      workspaceId,
      projectId,
      taskId,
    ).update({...changes, 'updated_at': FieldValue.serverTimestamp()});
  }

  @override
  Stream<List<TaskComment>> watchComments(
    String workspaceId,
    String projectId,
    String taskId,
  ) {
    return _comments(workspaceId, projectId, taskId)
        .orderBy('created_at')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TaskCommentModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Future<void> addComment({
    required String workspaceId,
    required String projectId,
    required String taskId,
    required String authorId,
    required String content,
  }) async {
    final commentDoc = _comments(workspaceId, projectId, taskId).doc();

    await commentDoc.set({
      'id': commentDoc.id,
      'task_id': taskId,
      'author_id': authorId,
      'content': content,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_edited': false,
    });
  }

  int _sortTasksByUpdatedAtDescending(TaskItem left, TaskItem right) {
    final leftTime = left.updatedAt ?? left.createdAt ?? DateTime(1970);
    final rightTime = right.updatedAt ?? right.createdAt ?? DateTime(1970);
    return rightTime.compareTo(leftTime);
  }

  Stream<List<TaskItem>> _watchTasksAcrossWorkspace({
    required String workspaceId,
    String? assignedTo,
  }) {
    late final StreamController<List<TaskItem>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? projectSubscription;
    final taskSubscriptions =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final taskBuckets = <String, List<TaskItem>>{};

    void emit() {
      if (controller.isClosed) {
        return;
      }

      final merged = taskBuckets.values
          .expand((tasks) => tasks)
          .toList(growable: false)
        ..sort(_sortTasksByUpdatedAtDescending);
      controller.add(merged);
    }

    Future<void> syncProjects(List<String> projectIds) async {
      final desiredProjectIds = projectIds.toSet();
      final currentProjectIds = taskSubscriptions.keys.toList(growable: false);

      for (final projectId in currentProjectIds) {
        if (desiredProjectIds.contains(projectId)) {
          continue;
        }
        await taskSubscriptions.remove(projectId)?.cancel();
        taskBuckets.remove(projectId);
      }

      for (final projectId in desiredProjectIds) {
        if (taskSubscriptions.containsKey(projectId)) {
          continue;
        }

        Query<Map<String, dynamic>> query = _tasks(workspaceId, projectId)
            .where('is_archived', isEqualTo: false);

        if (assignedTo != null) {
          query = query.where('assigned_to', isEqualTo: assignedTo);
        }

        taskSubscriptions[projectId] = query.snapshots().listen(
          (snapshot) {
            taskBuckets[projectId] = snapshot.docs
                .map(TaskItemModel.fromSnapshot)
                .toList(growable: false);
            emit();
          },
          onError: controller.addError,
        );
      }

      if (desiredProjectIds.isEmpty) {
        emit();
      }
    }

    controller = StreamController<List<TaskItem>>(
      onListen: () {
        projectSubscription = _projects(workspaceId)
            .where('is_archived', isEqualTo: false)
            .snapshots()
            .listen(
              (snapshot) {
                final projectIds = snapshot.docs
                    .map((document) => document.id)
                    .toList(growable: false);
                syncProjects(projectIds);
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await projectSubscription?.cancel();
        for (final subscription in taskSubscriptions.values) {
          await subscription.cancel();
        }
        taskSubscriptions.clear();
        taskBuckets.clear();
      },
    );

    return controller.stream;
  }
}
