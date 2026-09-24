import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../application/workspace_join_code_utils.dart';
import '../../domain/entities/workspace_join_code.dart';

final class WorkspaceJoinCodeModel extends WorkspaceJoinCode {
  const WorkspaceJoinCodeModel({
    required super.id,
    required super.workspaceId,
    required super.workspaceNameSnapshot,
    required super.workspaceDescriptionSnapshot,
    required super.code,
    required super.codeNormalized,
    required super.kind,
    required super.isActive,
    required super.maxUses,
    required super.usedCount,
    required super.expiresAt,
    required super.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  factory WorkspaceJoinCodeModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return WorkspaceJoinCodeModel(
      id: FirestoreValueParsers.string(data['id'], fallback: snapshot.id),
      workspaceId: FirestoreValueParsers.string(data['workspace_id']),
      workspaceNameSnapshot: FirestoreValueParsers.string(
        data['workspace_name_snapshot'],
        fallback: 'Workspace',
      ),
      workspaceDescriptionSnapshot: FirestoreValueParsers.string(
        data['workspace_description_snapshot'],
      ),
      code: FirestoreValueParsers.string(data['code']),
      codeNormalized: FirestoreValueParsers.string(data['code_normalized']),
      kind: WorkspaceJoinCodeKindMapper.fromValue(
        FirestoreValueParsers.string(data['kind']),
      ),
      isActive: FirestoreValueParsers.boolean(
        data['is_active'],
        fallback: true,
      ),
      maxUses: FirestoreValueParsers.integer(data['max_uses'], fallback: 1),
      usedCount: FirestoreValueParsers.integer(data['used_count']),
      expiresAt:
          FirestoreValueParsers.dateTime(data['expires_at']) ??
          DateTime.now().toUtc(),
      createdBy: FirestoreValueParsers.string(data['created_by']),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
    );
  }

  factory WorkspaceJoinCodeModel.fromLookupSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final normalized = FirestoreValueParsers.string(
      data['code_normalized'],
      fallback: snapshot.id,
    );

    return WorkspaceJoinCodeModel(
      id: FirestoreValueParsers.string(
        data['join_code_id'],
        fallback: FirestoreValueParsers.string(
          data['id'],
          fallback: snapshot.id,
        ),
      ),
      workspaceId: FirestoreValueParsers.string(data['workspace_id']),
      workspaceNameSnapshot: FirestoreValueParsers.string(
        data['workspace_name_snapshot'],
        fallback: 'Workspace',
      ),
      workspaceDescriptionSnapshot: FirestoreValueParsers.string(
        data['workspace_description_snapshot'],
      ),
      code: FirestoreValueParsers.string(
        data['code'],
        fallback: WorkspaceJoinCodeUtils.formatForDisplay(normalized),
      ),
      codeNormalized: normalized,
      kind: WorkspaceJoinCodeKindMapper.fromValue(
        FirestoreValueParsers.string(data['kind']),
      ),
      isActive: FirestoreValueParsers.boolean(
        data['is_active'],
        fallback: true,
      ),
      maxUses: FirestoreValueParsers.integer(data['max_uses'], fallback: 1),
      usedCount: FirestoreValueParsers.integer(data['used_count']),
      expiresAt:
          FirestoreValueParsers.dateTime(data['expires_at']) ??
          DateTime.now().toUtc(),
      createdBy: FirestoreValueParsers.string(data['created_by']),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
    );
  }
}
