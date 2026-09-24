import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/task_item.dart';

final class TaskCommentModel extends TaskComment {
  const TaskCommentModel({
    required super.id,
    required super.taskId,
    required super.authorId,
    required super.content,
    required super.isEdited,
    super.createdAt,
    super.updatedAt,
  });

  factory TaskCommentModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return TaskCommentModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      taskId: FirestoreValueParsers.string(data['task_id']),
      authorId: FirestoreValueParsers.string(data['author_id']),
      content: FirestoreValueParsers.string(data['content']),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
      isEdited: FirestoreValueParsers.boolean(data['is_edited']),
    );
  }
}
