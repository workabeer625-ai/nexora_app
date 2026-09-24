import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/workspace_join_code.dart';
import '../../domain/entities/workspace_join_request.dart';

final class WorkspaceJoinRequestModel extends WorkspaceJoinRequest {
  const WorkspaceJoinRequestModel({
    required super.userId,
    required super.workspaceId,
    required super.status,
    required super.joinCodeSnapshot,
    required super.requestedVia,
    required super.userDisplayNameSnapshot,
    required super.userEmailSnapshot,
    super.note,
    super.requestedAt,
    super.reviewedAt,
    super.reviewedBy,
  });

  factory WorkspaceJoinRequestModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final joinCodeSnapshot =
        (data['join_code_snapshot'] as Map<Object?, Object?>?)?.map(
          (key, value) => MapEntry('$key', value),
        ) ??
        const <String, dynamic>{};

    final note = FirestoreValueParsers.string(data['note']);
    final reviewedBy = FirestoreValueParsers.string(data['reviewed_by']);

    return WorkspaceJoinRequestModel(
      userId: FirestoreValueParsers.string(
        data['user_id'],
        fallback: snapshot.id,
      ),
      workspaceId: FirestoreValueParsers.string(data['workspace_id']),
      status: WorkspaceJoinRequestStatusMapper.fromValue(
        FirestoreValueParsers.string(data['status']),
      ),
      joinCodeSnapshot: WorkspaceJoinCodeSnapshot(
        joinCodeId: FirestoreValueParsers.string(
          joinCodeSnapshot['join_code_id'],
        ),
        code: FirestoreValueParsers.string(joinCodeSnapshot['code']),
        codeNormalized: FirestoreValueParsers.string(
          joinCodeSnapshot['code_normalized'],
        ),
        kind: WorkspaceJoinCodeKindMapper.fromValue(
          FirestoreValueParsers.string(joinCodeSnapshot['kind']),
        ),
        maxUses: FirestoreValueParsers.integer(
          joinCodeSnapshot['max_uses'],
          fallback: 1,
        ),
      ),
      requestedVia: WorkspaceJoinRequestViaMapper.fromValue(
        FirestoreValueParsers.string(data['requested_via']),
      ),
      userDisplayNameSnapshot: FirestoreValueParsers.string(
        data['user_display_name_snapshot'],
        fallback: 'Unknown user',
      ),
      userEmailSnapshot: FirestoreValueParsers.string(
        data['user_email_snapshot'],
      ),
      note: note.isEmpty ? null : note,
      requestedAt: FirestoreValueParsers.dateTime(data['requested_at']),
      reviewedAt: FirestoreValueParsers.dateTime(data['reviewed_at']),
      reviewedBy: reviewedBy.isEmpty ? null : reviewedBy,
    );
  }
}
