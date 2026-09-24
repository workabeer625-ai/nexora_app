import '../entities/workspace.dart';

abstract interface class WorkspaceRepository {
  Stream<List<Workspace>> watchUserWorkspaces(String userId);

  Stream<Workspace?> watchWorkspace(String workspaceId);

  Future<Workspace?> fetchWorkspace(String workspaceId);

  Stream<List<WorkspaceMember>> watchMembers(String workspaceId);

  Stream<WorkspaceMember?> watchMember(String workspaceId, String userId);

  Future<WorkspaceMember?> fetchMember(String workspaceId, String userId);

  Future<bool> isActiveMember(String workspaceId, String userId);

  Future<String> createWorkspace({
    required String ownerId,
    required String name,
    required String description,
  });
}
