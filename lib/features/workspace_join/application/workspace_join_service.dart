import '../../../core/errors/app_exception.dart';
import '../../../core/validators/input_validators.dart';
import '../../notifications/domain/entities/app_notification.dart';
import '../../notifications/domain/repositories/notification_repository.dart';
import '../../users/domain/repositories/user_profile_repository.dart';
import '../../workspaces/domain/repositories/workspace_repository.dart';
import '../domain/entities/workspace_join_code.dart';
import '../domain/entities/workspace_join_preview.dart';
import '../domain/entities/workspace_join_request.dart';
import '../domain/repositories/workspace_join_repository.dart';
import 'workspace_join_code_utils.dart';

final class WorkspaceJoinService {
  WorkspaceJoinService({
    required WorkspaceJoinRepository workspaceJoinRepository,
    required WorkspaceRepository workspaceRepository,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _workspaceJoinRepository = workspaceJoinRepository,
       _workspaceRepository = workspaceRepository,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository;

  final WorkspaceJoinRepository _workspaceJoinRepository;
  final WorkspaceRepository _workspaceRepository;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;

  Future<WorkspaceJoinPreview> resolveJoinCode(
    String rawCode, {
    String? userId,
  }) {
    final normalizedCode = WorkspaceJoinCodeUtils.normalize(rawCode);
    return _workspaceJoinRepository.resolveJoinCode(
      normalizedCode,
      userId: userId,
    );
  }

  Stream<List<WorkspaceJoinCode>> watchJoinCodes(String workspaceId) {
    return _workspaceJoinRepository.watchJoinCodes(workspaceId);
  }

  Stream<List<WorkspaceJoinRequest>> watchJoinRequests(String workspaceId) {
    return _workspaceJoinRepository.watchJoinRequests(workspaceId);
  }

  Stream<List<WorkspaceJoinRequest>> watchUserJoinRequests(String userId) {
    return _workspaceJoinRepository.watchUserJoinRequests(
      InputValidators.validateUid(userId),
    );
  }

  Future<WorkspaceJoinCode> createJoinCode({
    required String workspaceId,
    required String actorUserId,
    required WorkspaceJoinCodeKind kind,
    required int maxUses,
    required DateTime expiresAt,
  }) {
    if (!expiresAt.isAfter(DateTime.now())) {
      throw const ValidationException(
        'Join code expiry must be in the future.',
      );
    }

    final resolvedMaxUses = switch (kind) {
      WorkspaceJoinCodeKind.singleUse => 1,
      WorkspaceJoinCodeKind.multiUse => _validateMultiUseMaxUses(maxUses),
    };

    return _workspaceJoinRepository.createJoinCode(
      workspaceId: workspaceId,
      kind: kind,
      maxUses: resolvedMaxUses,
      expiresAt: expiresAt,
      createdBy: InputValidators.validateUid(
        actorUserId,
        fieldName: 'Actor user ID',
      ),
    );
  }

  Future<void> disableJoinCode({
    required String workspaceId,
    required String joinCodeId,
  }) {
    return _workspaceJoinRepository.disableJoinCode(
      workspaceId: workspaceId,
      joinCodeId: joinCodeId,
    );
  }

  Future<WorkspaceJoinCode> regenerateJoinCode({
    required String workspaceId,
    required String actorUserId,
    required WorkspaceJoinCode existingCode,
  }) async {
    await disableJoinCode(
      workspaceId: workspaceId,
      joinCodeId: existingCode.id,
    );

    return createJoinCode(
      workspaceId: workspaceId,
      actorUserId: actorUserId,
      kind: existingCode.kind,
      maxUses: existingCode.maxUses,
      expiresAt: existingCode.expiresAt,
    );
  }

  Future<void> submitJoinRequest({
    required String userId,
    required WorkspaceJoinPreview preview,
    required WorkspaceJoinRequestVia requestedVia,
    String? note,
  }) async {
    final normalizedUserId = InputValidators.validateUid(userId);
    if (!preview.canSubmitRequest) {
      throw ValidationException(preview.state.message);
    }

    final profile = await _userProfileRepository.fetchProfile(normalizedUserId);
    if (profile == null || !profile.isActive) {
      throw const NotFoundException(
        'Your profile could not be loaded. Sign in again and retry.',
      );
    }

    final normalizedNote = _normalizeNote(note);
    await _workspaceJoinRepository.submitJoinRequest(
      userId: normalizedUserId,
      preview: preview,
      requestedVia: requestedVia,
      userDisplayName: profile.displayName,
      userEmail: profile.email,
      note: normalizedNote,
    );
  }

  Future<void> approveJoinRequest({
    required String workspaceId,
    required String requesterUserId,
    required String reviewerUserId,
  }) async {
    await _workspaceJoinRepository.approveJoinRequest(
      workspaceId: workspaceId,
      requesterUserId: requesterUserId,
      reviewerUserId: reviewerUserId,
    );

    final workspace = await _workspaceRepository.fetchWorkspace(workspaceId);
    await _notificationRepository.createNotification(
      AppNotification(
        id: '',
        userId: requesterUserId,
        type: NotificationType.joinRequestApproved,
        title: 'Join request approved',
        body:
            'Your request to join ${workspace?.name ?? 'this workspace'} was approved.',
        entityType: NotificationEntityType.workspace,
        entityId: workspaceId,
        isRead: false,
      ),
    );
  }

  Future<void> rejectJoinRequest({
    required String workspaceId,
    required String requesterUserId,
    required String reviewerUserId,
  }) async {
    await _workspaceJoinRepository.rejectJoinRequest(
      workspaceId: workspaceId,
      requesterUserId: requesterUserId,
      reviewerUserId: reviewerUserId,
    );

    final workspace = await _workspaceRepository.fetchWorkspace(workspaceId);
    await _notificationRepository.createNotification(
      AppNotification(
        id: '',
        userId: requesterUserId,
        type: NotificationType.joinRequestRejected,
        title: 'Join request rejected',
        body:
            'Your request to join ${workspace?.name ?? 'this workspace'} was not approved.',
        entityType: NotificationEntityType.workspace,
        entityId: workspaceId,
        isRead: false,
      ),
    );
  }

  int _validateMultiUseMaxUses(int value) {
    if (value < 2 || value > 250) {
      throw const ValidationException(
        'Multi-use codes must allow between 2 and 250 approvals.',
      );
    }

    return value;
  }

  String? _normalizeNote(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length > 240) {
      throw const ValidationException(
        'Join request notes must be at most 240 characters.',
      );
    }

    return trimmed;
  }
}
