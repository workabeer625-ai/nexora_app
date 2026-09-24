import '../../../core/validators/input_validators.dart';
import '../domain/repositories/workspace_repository.dart';

final class WorkspaceManagementService {
  WorkspaceManagementService({required WorkspaceRepository workspaceRepository})
    : _workspaceRepository = workspaceRepository;

  final WorkspaceRepository _workspaceRepository;

  Future<String> createWorkspace({
    required String ownerId,
    required String name,
    required String description,
  }) {
    final normalizedName = InputValidators.validateRequiredText(
      name,
      fieldName: 'Workspace name',
      minLength: 2,
      maxLength: 80,
    );

    return _workspaceRepository.createWorkspace(
      ownerId: ownerId,
      name: normalizedName,
      description: description.trim(),
    );
  }
}
