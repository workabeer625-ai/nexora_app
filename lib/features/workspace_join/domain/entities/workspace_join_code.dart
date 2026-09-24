enum WorkspaceJoinCodeKind { singleUse, multiUse }

extension WorkspaceJoinCodeKindMapper on WorkspaceJoinCodeKind {
  String get value {
    return switch (this) {
      WorkspaceJoinCodeKind.singleUse => 'single_use',
      WorkspaceJoinCodeKind.multiUse => 'multi_use',
    };
  }

  String get label {
    return switch (this) {
      WorkspaceJoinCodeKind.singleUse => 'Single use',
      WorkspaceJoinCodeKind.multiUse => 'Multi use',
    };
  }

  static WorkspaceJoinCodeKind fromValue(String? value) {
    return switch (value) {
      'multi_use' => WorkspaceJoinCodeKind.multiUse,
      _ => WorkspaceJoinCodeKind.singleUse,
    };
  }
}

class WorkspaceJoinCode {
  const WorkspaceJoinCode({
    required this.id,
    required this.workspaceId,
    required this.workspaceNameSnapshot,
    required this.workspaceDescriptionSnapshot,
    required this.code,
    required this.codeNormalized,
    required this.kind,
    required this.isActive,
    required this.maxUses,
    required this.usedCount,
    required this.expiresAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String workspaceNameSnapshot;
  final String workspaceDescriptionSnapshot;
  final String code;
  final String codeNormalized;
  final WorkspaceJoinCodeKind kind;
  final bool isActive;
  final int maxUses;
  final int usedCount;
  final DateTime expiresAt;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get remainingUses {
    final remaining = maxUses - usedCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  bool get isExhausted => usedCount >= maxUses;

  bool get isAvailable => isActive && !isExpired && !isExhausted;
}
