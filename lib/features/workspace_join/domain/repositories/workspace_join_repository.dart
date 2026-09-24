import '../entities/workspace_join_code.dart';
import '../entities/workspace_join_preview.dart';
import '../entities/workspace_join_request.dart';

abstract interface class WorkspaceJoinRepository {
  Future<WorkspaceJoinPreview> resolveJoinCode(
    String normalizedCode, {
    String? userId,
  });

  Stream<List<WorkspaceJoinCode>> watchJoinCodes(String workspaceId);

  Stream<List<WorkspaceJoinRequest>> watchJoinRequests(String workspaceId);

  Stream<List<WorkspaceJoinRequest>> watchUserJoinRequests(String userId);

  Future<WorkspaceJoinCode> createJoinCode({
    required String workspaceId,
    required WorkspaceJoinCodeKind kind,
    required int maxUses,
    required DateTime expiresAt,
    required String createdBy,
  });

  Future<void> disableJoinCode({
    required String workspaceId,
    required String joinCodeId,
  });

  Future<void> submitJoinRequest({
    required String userId,
    required WorkspaceJoinPreview preview,
    required WorkspaceJoinRequestVia requestedVia,
    required String userDisplayName,
    required String userEmail,
    String? note,
  });

  Future<void> approveJoinRequest({
    required String workspaceId,
    required String requesterUserId,
    required String reviewerUserId,
  });

  Future<void> rejectJoinRequest({
    required String workspaceId,
    required String requesterUserId,
    required String reviewerUserId,
  });
}
