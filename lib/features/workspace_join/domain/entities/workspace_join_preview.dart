import 'workspace_join_code.dart';

enum WorkspaceJoinPreviewState {
  available,
  disabled,
  expired,
  exhausted,
  alreadyMember,
  pendingRequest,
}

extension WorkspaceJoinPreviewStateMapper on WorkspaceJoinPreviewState {
  String get label {
    return switch (this) {
      WorkspaceJoinPreviewState.available => 'Ready to request',
      WorkspaceJoinPreviewState.disabled => 'Disabled',
      WorkspaceJoinPreviewState.expired => 'Expired',
      WorkspaceJoinPreviewState.exhausted => 'Used up',
      WorkspaceJoinPreviewState.alreadyMember => 'Already a member',
      WorkspaceJoinPreviewState.pendingRequest => 'Request pending',
    };
  }

  String get message {
    return switch (this) {
      WorkspaceJoinPreviewState.available =>
        'You can send a join request to this workspace.',
      WorkspaceJoinPreviewState.disabled =>
        'This join code has been disabled by an administrator.',
      WorkspaceJoinPreviewState.expired =>
        'This join code has expired and can no longer be used.',
      WorkspaceJoinPreviewState.exhausted =>
        'This join code has reached its maximum approved uses.',
      WorkspaceJoinPreviewState.alreadyMember =>
        'You already belong to this workspace.',
      WorkspaceJoinPreviewState.pendingRequest =>
        'Your join request is already waiting for admin approval.',
    };
  }
}

class WorkspaceJoinPreview {
  const WorkspaceJoinPreview({required this.joinCode, required this.state});

  final WorkspaceJoinCode joinCode;
  final WorkspaceJoinPreviewState state;

  String get workspaceId => joinCode.workspaceId;

  String get workspaceName => joinCode.workspaceNameSnapshot;

  String get workspaceDescription => joinCode.workspaceDescriptionSnapshot;

  bool get canSubmitRequest => state == WorkspaceJoinPreviewState.available;
}
