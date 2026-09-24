import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/project.dart';

final class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.workspaceId,
    required super.name,
    required super.description,
    required super.status,
    required super.createdBy,
    required super.isArchived,
    super.createdAt,
    super.updatedAt,
  });

  factory ProjectModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return ProjectModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      workspaceId: FirestoreValueParsers.string(data['workspace_id']),
      name: FirestoreValueParsers.string(data['name'], fallback: 'Untitled'),
      description: FirestoreValueParsers.string(data['description']),
      status: ProjectStatusMapper.fromValue(
        FirestoreValueParsers.string(data['status'], fallback: 'active'),
      ),
      createdBy: FirestoreValueParsers.string(data['created_by']),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
      isArchived: FirestoreValueParsers.boolean(
        data['is_archived'],
        fallback: false,
      ),
    );
  }
}
