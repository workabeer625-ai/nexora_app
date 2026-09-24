import '../entities/project.dart';

abstract interface class ProjectRepository {
  Stream<List<Project>> watchProjects(String workspaceId);

  Stream<Project?> watchProject(String workspaceId, String projectId);

  Future<String> createProject({
    required String workspaceId,
    required String name,
    required String description,
    required ProjectStatus status,
    required String createdBy,
  });
}
