import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../workspaces/data/models/workspace_member_model.dart';
import '../../../workspaces/data/models/workspace_model.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../application/workspace_join_code_utils.dart';
import '../../domain/entities/workspace_join_code.dart';
import '../../domain/entities/workspace_join_preview.dart';
import '../../domain/entities/workspace_join_request.dart';
import '../../domain/repositories/workspace_join_repository.dart';
import '../models/workspace_join_code_model.dart';
import '../models/workspace_join_request_model.dart';

final class FirestoreWorkspaceJoinRepository
    implements WorkspaceJoinRepository {
  FirestoreWorkspaceJoinRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  FirebaseFirestore get _firestore => _firestoreService.instance;

  DocumentReference<Map<String, dynamic>> _workspaceDoc(String workspaceId) {
    return _firestoreService.document(FirestorePaths.workspace(workspaceId));
  }

  DocumentReference<Map<String, dynamic>> _joinCodeLookupDoc(
    String codeNormalized,
  ) {
    return _firestoreService.document(
      FirestorePaths.joinCodeLookupDoc(codeNormalized),
    );
  }

  CollectionReference<Map<String, dynamic>> _joinCodes(String workspaceId) {
    return _firestoreService.collection(
      FirestorePaths.workspaceJoinCodes(workspaceId),
    );
  }

  DocumentReference<Map<String, dynamic>> _joinCodeDoc(
    String workspaceId,
    String joinCodeId,
  ) {
    return _firestoreService.document(
      FirestorePaths.workspaceJoinCode(workspaceId, joinCodeId),
    );
  }

  CollectionReference<Map<String, dynamic>> _joinRequests(String workspaceId) {
    return _firestoreService.collection(
      FirestorePaths.workspaceJoinRequests(workspaceId),
    );
  }

  DocumentReference<Map<String, dynamic>> _joinRequestDoc(
    String workspaceId,
    String userId,
  ) {
    return _firestoreService.document(
      FirestorePaths.workspaceJoinRequest(workspaceId, userId),
    );
  }

  DocumentReference<Map<String, dynamic>> _memberDoc(
    String workspaceId,
    String userId,
  ) {
    return _firestoreService.document(
      FirestorePaths.workspaceMember(workspaceId, userId),
    );
  }

  @override
  Future<WorkspaceJoinPreview> resolveJoinCode(
    String normalizedCode, {
    String? userId,
  }) async {
    final lookupSnapshot = await _joinCodeLookupDoc(normalizedCode).get();
    if (!lookupSnapshot.exists) {
      throw const NotFoundException(
        'Join code not found. Check the code and try again.',
      );
    }

    final joinCode = WorkspaceJoinCodeModel.fromLookupSnapshot(lookupSnapshot);
    if (joinCode.workspaceId.isEmpty || joinCode.id.isEmpty) {
      throw const ValidationException(
        'This join code lookup entry is invalid. Regenerate the code.',
      );
    }
    var state = _stateForJoinCode(joinCode);

    if (userId != null && state == WorkspaceJoinPreviewState.available) {
      final memberSnapshot = await _memberDoc(
        joinCode.workspaceId,
        userId,
      ).get();
      if (memberSnapshot.exists) {
        final member = WorkspaceMemberModel.fromSnapshot(memberSnapshot);
        if (member.status == WorkspaceMemberStatus.active) {
          state = WorkspaceJoinPreviewState.alreadyMember;
        }
      }

      if (state == WorkspaceJoinPreviewState.available) {
        final requestSnapshot = await _joinRequestDoc(
          joinCode.workspaceId,
          userId,
        ).get();
        if (requestSnapshot.exists) {
          final request = WorkspaceJoinRequestModel.fromSnapshot(
            requestSnapshot,
          );
          if (request.status == WorkspaceJoinRequestStatus.pending) {
            state = WorkspaceJoinPreviewState.pendingRequest;
          }
        }
      }
    }

    return WorkspaceJoinPreview(joinCode: joinCode, state: state);
  }

  @override
  Stream<List<WorkspaceJoinCode>> watchJoinCodes(String workspaceId) {
    return _joinCodes(workspaceId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkspaceJoinCodeModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<WorkspaceJoinRequest>> watchJoinRequests(String workspaceId) {
    return _joinRequests(workspaceId)
        .orderBy('requested_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkspaceJoinRequestModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<WorkspaceJoinRequest>> watchUserJoinRequests(String userId) {
    return _firestore
        .collectionGroup(FirestorePaths.joinRequests)
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(WorkspaceJoinRequestModel.fromSnapshot)
              .toList(growable: false);
          final sorted = requests.toList(growable: true)
            ..sort((a, b) {
              final aTime = a.requestedAt?.millisecondsSinceEpoch ?? 0;
              final bTime = b.requestedAt?.millisecondsSinceEpoch ?? 0;
              return bTime.compareTo(aTime);
            });
          return sorted;
        });
  }

  @override
  Future<WorkspaceJoinCode> createJoinCode({
    required String workspaceId,
    required WorkspaceJoinCodeKind kind,
    required int maxUses,
    required DateTime expiresAt,
    required String createdBy,
  }) async {
    final workspaceSnapshot = await _workspaceDoc(workspaceId).get();
    if (!workspaceSnapshot.exists) {
      throw const NotFoundException('Workspace not found.');
    }

    final workspace = WorkspaceModel.fromSnapshot(workspaceSnapshot);
    if (workspace.isArchived) {
      throw const ValidationException(
        'Archived workspaces cannot issue new join codes.',
      );
    }

    for (var attempt = 0; attempt < 5; attempt += 1) {
      final code = WorkspaceJoinCodeUtils.generateCode();
      final normalized = WorkspaceJoinCodeUtils.normalize(code);
      final duplicateSnapshot = await _joinCodeLookupDoc(normalized).get();
      if (duplicateSnapshot.exists) {
        continue;
      }

      final doc = _joinCodes(workspaceId).doc();
      final batch = _firestore.batch();
      batch.set(doc, {
        'id': doc.id,
        'workspace_id': workspaceId,
        'workspace_name_snapshot': workspace.name,
        'workspace_description_snapshot': workspace.description,
        'code': code,
        'code_normalized': normalized,
        'kind': kind.value,
        'is_active': true,
        'max_uses': maxUses,
        'used_count': 0,
        'expires_at': Timestamp.fromDate(expiresAt.toUtc()),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
      });
      batch.set(_joinCodeLookupDoc(normalized), {
        'id': doc.id,
        'workspace_id': workspaceId,
        'join_code_id': doc.id,
        'code_normalized': normalized,
        'code': code,
        'workspace_name_snapshot': workspace.name,
        'workspace_description_snapshot': workspace.description,
        'kind': kind.value,
        'is_active': true,
        'max_uses': maxUses,
        'used_count': 0,
        'expires_at': Timestamp.fromDate(expiresAt.toUtc()),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
      });
      await batch.commit();

      final createdSnapshot = await doc.get();
      return WorkspaceJoinCodeModel.fromSnapshot(createdSnapshot);
    }

    throw const ValidationException(
      'Could not generate a unique join code. Please try again.',
    );
  }

  @override
  Future<void> disableJoinCode({
    required String workspaceId,
    required String joinCodeId,
  }) async {
    final joinCodeSnapshot = await _joinCodeDoc(workspaceId, joinCodeId).get();
    if (!joinCodeSnapshot.exists) {
      throw const NotFoundException('Join code not found.');
    }

    final joinCode = WorkspaceJoinCodeModel.fromSnapshot(joinCodeSnapshot);
    final batch = _firestore.batch();
    batch.update(_joinCodeDoc(workspaceId, joinCodeId), {
      'is_active': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
    batch.update(_joinCodeLookupDoc(joinCode.codeNormalized), {
      'is_active': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> submitJoinRequest({
    required String userId,
    required WorkspaceJoinPreview preview,
    required WorkspaceJoinRequestVia requestedVia,
    required String userDisplayName,
    required String userEmail,
    String? note,
  }) {
    final requestRef = _joinRequestDoc(preview.workspaceId, userId);
    final joinCodeLookupRef = _joinCodeLookupDoc(
      preview.joinCode.codeNormalized,
    );
    final memberRef = _memberDoc(preview.workspaceId, userId);

    return _firestore.runTransaction((transaction) async {
      final joinCodeSnapshot = await transaction.get(joinCodeLookupRef);
      if (!joinCodeSnapshot.exists) {
        throw const NotFoundException(
          'This join code no longer exists. Ask an admin for a new one.',
        );
      }

      final joinCode = WorkspaceJoinCodeModel.fromLookupSnapshot(
        joinCodeSnapshot,
      );
      if (joinCode.workspaceId != preview.workspaceId ||
          joinCode.id != preview.joinCode.id) {
        throw const ValidationException(
          'This join code no longer matches the selected workspace. Refresh and try again.',
        );
      }

      final currentState = _stateForJoinCode(joinCode);
      if (currentState != WorkspaceJoinPreviewState.available) {
        throw ValidationException(currentState.message);
      }

      final memberSnapshot = await transaction.get(memberRef);
      if (memberSnapshot.exists) {
        final member = WorkspaceMemberModel.fromSnapshot(memberSnapshot);
        if (member.status == WorkspaceMemberStatus.active) {
          throw const ValidationException(
            'You are already a member of this workspace.',
          );
        }
      }

      final requestSnapshot = await transaction.get(requestRef);
      if (requestSnapshot.exists) {
        final request = WorkspaceJoinRequestModel.fromSnapshot(requestSnapshot);
        if (request.status == WorkspaceJoinRequestStatus.pending) {
          throw const ValidationException(
            'A join request is already pending for this workspace.',
          );
        }
      }

      transaction.set(requestRef, {
        'user_id': userId,
        'workspace_id': preview.workspaceId,
        'status': WorkspaceJoinRequestStatus.pending.value,
        'requested_at': FieldValue.serverTimestamp(),
        'reviewed_at': null,
        'reviewed_by': null,
        'join_code_snapshot': {
          'join_code_id': joinCode.id,
          'code': joinCode.code,
          'code_normalized': joinCode.codeNormalized,
          'kind': joinCode.kind.value,
          'max_uses': joinCode.maxUses,
        },
        'requested_via': requestedVia.value,
        'note': note,
        'user_display_name_snapshot': userDisplayName,
        'user_email_snapshot': userEmail,
      });
    });
  }

  @override
  Future<void> approveJoinRequest({
    required String workspaceId,
    required String requesterUserId,
    required String reviewerUserId,
  }) {
    final workspaceRef = _workspaceDoc(workspaceId);
    final requestRef = _joinRequestDoc(workspaceId, requesterUserId);
    final memberRef = _memberDoc(workspaceId, requesterUserId);

    return _firestore.runTransaction((transaction) async {
      final workspaceSnapshot = await transaction.get(workspaceRef);
      if (!workspaceSnapshot.exists) {
        throw const NotFoundException('Workspace not found.');
      }

      final workspace = WorkspaceModel.fromSnapshot(workspaceSnapshot);
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw const NotFoundException('Join request not found.');
      }

      final joinRequest = WorkspaceJoinRequestModel.fromSnapshot(
        requestSnapshot,
      );
      if (joinRequest.status != WorkspaceJoinRequestStatus.pending) {
        throw const ValidationException(
          'Only pending join requests can be approved.',
        );
      }

      final memberSnapshot = await transaction.get(memberRef);
      if (memberSnapshot.exists) {
        final member = WorkspaceMemberModel.fromSnapshot(memberSnapshot);
        if (member.status == WorkspaceMemberStatus.active) {
          throw const ValidationException(
            'This user is already a member of the workspace.',
          );
        }
      }

      final joinCodeRef = _joinCodeDoc(
        workspaceId,
        joinRequest.joinCodeSnapshot.joinCodeId,
      );
      final joinCodeSnapshot = await transaction.get(joinCodeRef);
      if (!joinCodeSnapshot.exists) {
        throw const ValidationException(
          'The join code used for this request no longer exists.',
        );
      }

      final joinCode = WorkspaceJoinCodeModel.fromSnapshot(joinCodeSnapshot);
      final joinState = _stateForJoinCode(joinCode);
      if (joinState != WorkspaceJoinPreviewState.available) {
        throw ValidationException(joinState.message);
      }

      final shouldIncrement = !workspace.memberIds.contains(requesterUserId);
      final nextUsedCount = joinCode.usedCount + 1;
      final shouldRemainActive =
          joinCode.isActive &&
          joinCode.expiresAt.isAfter(DateTime.now()) &&
          nextUsedCount < joinCode.maxUses;

      transaction.set(memberRef, {
        'workspace_id': workspaceId,
        'user_id': requesterUserId,
        'role': WorkspaceRole.member.value,
        'joined_at': FieldValue.serverTimestamp(),
        'status': WorkspaceMemberStatus.active.value,
        'source': 'join_code_request',
        'approved_by': reviewerUserId,
        'join_request_id': requesterUserId,
        'join_code_id': joinCode.id,
      });
      transaction.update(workspaceRef, {
        'member_ids': FieldValue.arrayUnion(<String>[requesterUserId]),
        'member_count': FieldValue.increment(shouldIncrement ? 1 : 0),
        'updated_at': FieldValue.serverTimestamp(),
      });
      transaction.update(requestRef, {
        'status': WorkspaceJoinRequestStatus.approved.value,
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': reviewerUserId,
      });
      transaction.update(joinCodeRef, {
        'used_count': nextUsedCount,
        'is_active': shouldRemainActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
      transaction.update(_joinCodeLookupDoc(joinCode.codeNormalized), {
        'used_count': nextUsedCount,
        'is_active': shouldRemainActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> rejectJoinRequest({
    required String workspaceId,
    required String requesterUserId,
    required String reviewerUserId,
  }) {
    final requestRef = _joinRequestDoc(workspaceId, requesterUserId);

    return _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw const NotFoundException('Join request not found.');
      }

      final joinRequest = WorkspaceJoinRequestModel.fromSnapshot(
        requestSnapshot,
      );
      if (joinRequest.status != WorkspaceJoinRequestStatus.pending) {
        throw const ValidationException(
          'Only pending join requests can be rejected.',
        );
      }

      transaction.update(requestRef, {
        'status': WorkspaceJoinRequestStatus.rejected.value,
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': reviewerUserId,
      });
    });
  }

  WorkspaceJoinPreviewState _stateForJoinCode(WorkspaceJoinCode joinCode) {
    if (!joinCode.isActive) {
      return WorkspaceJoinPreviewState.disabled;
    }

    if (joinCode.isExpired) {
      return WorkspaceJoinPreviewState.expired;
    }

    if (joinCode.isExhausted) {
      return WorkspaceJoinPreviewState.exhausted;
    }

    return WorkspaceJoinPreviewState.available;
  }
}
