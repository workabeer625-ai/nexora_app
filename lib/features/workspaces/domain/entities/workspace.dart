enum WorkspaceRole { owner, admin, member }

extension WorkspaceRoleMapper on WorkspaceRole {
  String get value {
    return switch (this) {
      WorkspaceRole.owner => 'owner',
      WorkspaceRole.admin => 'admin',
      WorkspaceRole.member => 'member',
    };
  }

  String get label {
    return switch (this) {
      WorkspaceRole.owner => 'Owner',
      WorkspaceRole.admin => 'Admin',
      WorkspaceRole.member => 'Member',
    };
  }

  static WorkspaceRole fromValue(String? value) {
    return switch (value) {
      'owner' => WorkspaceRole.owner,
      'admin' => WorkspaceRole.admin,
      _ => WorkspaceRole.member,
    };
  }
}

enum WorkspaceMemberStatus { active, invited, removed }

extension WorkspaceMemberStatusMapper on WorkspaceMemberStatus {
  String get value {
    return switch (this) {
      WorkspaceMemberStatus.active => 'active',
      WorkspaceMemberStatus.invited => 'invited',
      WorkspaceMemberStatus.removed => 'removed',
    };
  }

  static WorkspaceMemberStatus fromValue(String? value) {
    return switch (value) {
      'invited' => WorkspaceMemberStatus.invited,
      'removed' => WorkspaceMemberStatus.removed,
      _ => WorkspaceMemberStatus.active,
    };
  }
}

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.isArchived,
    this.createdAt,
    this.updatedAt,
    this.memberIds = const <String>[],
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final List<String> memberIds;
  final int memberCount;
}

class WorkspaceMember {
  const WorkspaceMember({
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  final String workspaceId;
  final String userId;
  final WorkspaceRole role;
  final WorkspaceMemberStatus status;
  final DateTime? joinedAt;
}
