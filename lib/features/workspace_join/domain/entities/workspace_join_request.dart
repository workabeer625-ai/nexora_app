import 'workspace_join_code.dart';

enum WorkspaceJoinRequestStatus { pending, approved, rejected }

extension WorkspaceJoinRequestStatusMapper on WorkspaceJoinRequestStatus {
  String get value {
    return switch (this) {
      WorkspaceJoinRequestStatus.pending => 'pending',
      WorkspaceJoinRequestStatus.approved => 'approved',
      WorkspaceJoinRequestStatus.rejected => 'rejected',
    };
  }

  String get label {
    return switch (this) {
      WorkspaceJoinRequestStatus.pending => 'Pending',
      WorkspaceJoinRequestStatus.approved => 'Approved',
      WorkspaceJoinRequestStatus.rejected => 'Rejected',
    };
  }

  static WorkspaceJoinRequestStatus fromValue(String? value) {
    return switch (value) {
      'approved' => WorkspaceJoinRequestStatus.approved,
      'rejected' => WorkspaceJoinRequestStatus.rejected,
      _ => WorkspaceJoinRequestStatus.pending,
    };
  }
}

enum WorkspaceJoinRequestVia { manualCode, qrScan, qrGallery }

extension WorkspaceJoinRequestViaMapper on WorkspaceJoinRequestVia {
  String get value {
    return switch (this) {
      WorkspaceJoinRequestVia.manualCode => 'manual_code',
      WorkspaceJoinRequestVia.qrScan => 'qr_scan',
      WorkspaceJoinRequestVia.qrGallery => 'qr_gallery',
    };
  }

  String get label {
    return switch (this) {
      WorkspaceJoinRequestVia.manualCode => 'Manual code',
      WorkspaceJoinRequestVia.qrScan => 'QR scan',
      WorkspaceJoinRequestVia.qrGallery => 'QR gallery',
    };
  }

  static WorkspaceJoinRequestVia fromValue(String? value) {
    return switch (value) {
      'qr_scan' => WorkspaceJoinRequestVia.qrScan,
      'qr_gallery' => WorkspaceJoinRequestVia.qrGallery,
      _ => WorkspaceJoinRequestVia.manualCode,
    };
  }
}

class WorkspaceJoinCodeSnapshot {
  const WorkspaceJoinCodeSnapshot({
    required this.joinCodeId,
    required this.code,
    required this.codeNormalized,
    required this.kind,
    required this.maxUses,
  });

  final String joinCodeId;
  final String code;
  final String codeNormalized;
  final WorkspaceJoinCodeKind kind;
  final int maxUses;
}

class WorkspaceJoinRequest {
  const WorkspaceJoinRequest({
    required this.userId,
    required this.workspaceId,
    required this.status,
    required this.joinCodeSnapshot,
    required this.requestedVia,
    required this.userDisplayNameSnapshot,
    required this.userEmailSnapshot,
    this.note,
    this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String userId;
  final String workspaceId;
  final WorkspaceJoinRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final WorkspaceJoinCodeSnapshot joinCodeSnapshot;
  final WorkspaceJoinRequestVia requestedVia;
  final String? note;
  final String userDisplayNameSnapshot;
  final String userEmailSnapshot;
}
