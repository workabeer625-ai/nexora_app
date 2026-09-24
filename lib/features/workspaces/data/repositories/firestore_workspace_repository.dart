import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../models/workspace_member_model.dart';
import '../models/workspace_model.dart';

final class FirestoreWorkspaceRepository implements WorkspaceRepository {
  FirestoreWorkspaceRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _workspaces {
    return _firestoreService.collection(FirestorePaths.workspaces);
  }

  DocumentReference<Map<String, dynamic>> _workspaceDoc(String workspaceId) {
    return _firestoreService.document(FirestorePaths.workspace(workspaceId));
  }

  CollectionReference<Map<String, dynamic>> _members(String workspaceId) {
    return _firestoreService.collection(
      FirestorePaths.workspaceMembers(workspaceId),
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
  Stream<List<Workspace>> watchUserWorkspaces(String userId) {
    return _workspaces
        .where('member_ids', arrayContains: userId)
        .where('is_archived', isEqualTo: false)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkspaceModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Stream<Workspace?> watchWorkspace(String workspaceId) {
    return _workspaceDoc(workspaceId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return WorkspaceModel.fromSnapshot(snapshot);
    });
  }

  @override
  Future<Workspace?> fetchWorkspace(String workspaceId) async {
    final snapshot = await _workspaceDoc(workspaceId).get();
    if (!snapshot.exists) {
      return null;
    }

    return WorkspaceModel.fromSnapshot(snapshot);
  }

  @override
  Stream<List<WorkspaceMember>> watchMembers(String workspaceId) {
    return _members(workspaceId)
        .where('status', isEqualTo: WorkspaceMemberStatus.active.value)
        .orderBy('joined_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkspaceMemberModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Stream<WorkspaceMember?> watchMember(String workspaceId, String userId) {
    return _memberDoc(workspaceId, userId).snapshots().asyncMap((
      snapshot,
    ) async {
      if (snapshot.exists) {
        return WorkspaceMemberModel.fromSnapshot(snapshot);
      }

      final workspace = await fetchWorkspace(workspaceId);
      return _fallbackMemberFromWorkspace(workspace, userId);
    });
  }

  @override
  Future<WorkspaceMember?> fetchMember(
    String workspaceId,
    String userId,
  ) async {
    final snapshot = await _memberDoc(workspaceId, userId).get();
    if (snapshot.exists) {
      return WorkspaceMemberModel.fromSnapshot(snapshot);
    }

    final workspace = await fetchWorkspace(workspaceId);
    return _fallbackMemberFromWorkspace(workspace, userId);
  }

  @override
  Future<bool> isActiveMember(String workspaceId, String userId) async {
    final member = await fetchMember(workspaceId, userId);
    return member?.status == WorkspaceMemberStatus.active;
  }

  @override
  Future<String> createWorkspace({
    required String ownerId,
    required String name,
    required String description,
  }) async {
    final workspaceDoc = _workspaces.doc();
    final batch = _firestoreService.batch();

    batch.set(workspaceDoc, {
      'id': workspaceDoc.id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_archived': false,
      'member_ids': <String>[ownerId],
      'member_count': 1,
    });

    batch.set(_memberDoc(workspaceDoc.id, ownerId), {
      'workspace_id': workspaceDoc.id,
      'user_id': ownerId,
      'role': WorkspaceRole.owner.value,
      'joined_at': FieldValue.serverTimestamp(),
      'status': WorkspaceMemberStatus.active.value,
    });

    await batch.commit();
    return workspaceDoc.id;
  }

  WorkspaceMember? _fallbackMemberFromWorkspace(
    Workspace? workspace,
    String userId,
  ) {
    if (workspace == null || !workspace.memberIds.contains(userId)) {
      return null;
    }

    return WorkspaceMember(
      workspaceId: workspace.id,
      userId: userId,
      role: workspace.ownerId == userId
          ? WorkspaceRole.owner
          : WorkspaceRole.member,
      status: WorkspaceMemberStatus.active,
      joinedAt: workspace.createdAt,
    );
  }
}
