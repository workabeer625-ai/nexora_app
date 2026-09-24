import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/workspace.dart';

final class WorkspaceMemberModel extends WorkspaceMember {
  const WorkspaceMemberModel({
    required super.workspaceId,
    required super.userId,
    required super.role,
    required super.status,
    super.joinedAt,
  });

  factory WorkspaceMemberModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return WorkspaceMemberModel(
      workspaceId: FirestoreValueParsers.string(data['workspace_id']),
      userId: FirestoreValueParsers.string(
        data['user_id'],
        fallback: snapshot.id,
      ),
      role: WorkspaceRoleMapper.fromValue(
        FirestoreValueParsers.string(data['role'], fallback: 'member'),
      ),
      status: WorkspaceMemberStatusMapper.fromValue(
        FirestoreValueParsers.string(data['status'], fallback: 'active'),
      ),
      joinedAt: FirestoreValueParsers.dateTime(data['joined_at']),
    );
  }
}
