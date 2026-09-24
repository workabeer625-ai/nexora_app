import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/task_item.dart';

final class TaskItemModel extends TaskItem {
  const TaskItemModel({
    required super.id,
    required super.workspaceId,
    required super.projectId,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.createdBy,
    required super.progress,
    required super.isBlocked,
    required super.reviewStatus,
    required super.isArchived,
    super.assignedTo,
    super.startDate,
    super.dueDate,
    super.blockedReason,
    super.createdAt,
    super.updatedAt,
    super.completedAt,
  });

  factory TaskItemModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final assignedTo = FirestoreValueParsers.string(data['assigned_to']);
    final blockedReason = FirestoreValueParsers.string(data['blocked_reason']);

    return TaskItemModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      workspaceId: FirestoreValueParsers.string(data['workspace_id']),
      projectId: FirestoreValueParsers.string(data['project_id']),
      title: FirestoreValueParsers.string(data['title'], fallback: 'Untitled'),
      description: FirestoreValueParsers.string(data['description']),
      status: TaskStatusMapper.fromValue(
        FirestoreValueParsers.string(data['status'], fallback: 'todo'),
      ),
      priority: TaskPriorityMapper.fromValue(
        FirestoreValueParsers.string(data['priority'], fallback: 'medium'),
      ),
      assignedTo: assignedTo.isEmpty ? null : assignedTo,
      createdBy: FirestoreValueParsers.string(data['created_by']),
      startDate: FirestoreValueParsers.dateTime(data['start_date']),
      dueDate: FirestoreValueParsers.dateTime(data['due_date']),
      progress: FirestoreValueParsers.integer(data['progress']),
      isBlocked: FirestoreValueParsers.boolean(
        data['is_blocked'],
        fallback: false,
      ),
      blockedReason: blockedReason.isEmpty ? null : blockedReason,
      reviewStatus: ReviewStatusMapper.fromValue(
        FirestoreValueParsers.string(data['review_status'], fallback: 'none'),
      ),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
      completedAt: FirestoreValueParsers.dateTime(data['completed_at']),
      isArchived: FirestoreValueParsers.boolean(
        data['is_archived'],
        fallback: false,
      ),
    );
  }
}
