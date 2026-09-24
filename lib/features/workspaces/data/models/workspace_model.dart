import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/workspace.dart';

final class WorkspaceModel extends Workspace {
  const WorkspaceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.isArchived,
    super.createdAt,
    super.updatedAt,
    super.memberIds,
    super.memberCount,
  });

  factory WorkspaceModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return WorkspaceModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      name: FirestoreValueParsers.string(data['name'], fallback: 'Untitled'),
      description: FirestoreValueParsers.string(data['description']),
      ownerId: FirestoreValueParsers.string(data['owner_id']),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
      isArchived: FirestoreValueParsers.boolean(
        data['is_archived'],
        fallback: false,
      ),
      memberIds: FirestoreValueParsers.stringList(data['member_ids']),
      memberCount: FirestoreValueParsers.integer(data['member_count']),
    );
  }
}
