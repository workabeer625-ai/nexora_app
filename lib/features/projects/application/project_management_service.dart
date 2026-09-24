import '../../../core/validators/input_validators.dart';
import '../domain/entities/project.dart';
import '../domain/repositories/project_repository.dart';

final class ProjectManagementService {
  ProjectManagementService({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository;

  final ProjectRepository _projectRepository;

  Future<String> createProject({
    required String workspaceId,
    required String name,
    required String description,
    required ProjectStatus status,
    required String createdBy,
  }) {
    final normalizedName = InputValidators.validateRequiredText(
      name,
      fieldName: 'Project name',
      minLength: 2,
      maxLength: 80,
    );

    return _projectRepository.createProject(
      workspaceId: workspaceId,
      name: normalizedName,
      description: description.trim(),
      status: status,
      createdBy: createdBy,
    );
  }
}
