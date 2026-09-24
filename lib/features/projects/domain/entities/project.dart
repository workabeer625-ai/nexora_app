enum ProjectStatus { planned, active, onHold, completed }

extension ProjectStatusMapper on ProjectStatus {
  String get value {
    return switch (this) {
      ProjectStatus.planned => 'planned',
      ProjectStatus.active => 'active',
      ProjectStatus.onHold => 'on_hold',
      ProjectStatus.completed => 'completed',
    };
  }

  String get label {
    return switch (this) {
      ProjectStatus.planned => 'Planned',
      ProjectStatus.active => 'Active',
      ProjectStatus.onHold => 'On hold',
      ProjectStatus.completed => 'Completed',
    };
  }

  static ProjectStatus fromValue(String? value) {
    return switch (value) {
      'planned' => ProjectStatus.planned,
      'on_hold' => ProjectStatus.onHold,
      'completed' => ProjectStatus.completed,
      _ => ProjectStatus.active,
    };
  }
}

class Project {
  const Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.isArchived,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final ProjectStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
}
