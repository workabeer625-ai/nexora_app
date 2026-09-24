enum UserRole { admin, member }

extension UserRoleMapper on UserRole {
  String get value {
    return switch (this) {
      UserRole.admin => 'admin',
      UserRole.member => 'member',
    };
  }

  static UserRole fromValue(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      _ => UserRole.member,
    };
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
