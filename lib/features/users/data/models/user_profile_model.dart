import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_value_parsers.dart';
import '../../domain/entities/user_profile.dart';

final class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.displayName,
    required super.email,
    required super.role,
    required super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      uid: profile.uid,
      displayName: profile.displayName,
      email: profile.email,
      role: profile.role,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      isActive: profile.isActive,
    );
  }

  factory UserProfileModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return UserProfileModel(
      uid: FirestoreValueParsers.string(data['uid'], fallback: snapshot.id),
      displayName: FirestoreValueParsers.string(
        data['display_name'],
        fallback: 'Unnamed user',
      ),
      email: FirestoreValueParsers.string(data['email']),
      role: UserRoleMapper.fromValue(
        FirestoreValueParsers.string(data['role'], fallback: 'member'),
      ),
      createdAt: FirestoreValueParsers.dateTime(data['created_at']),
      updatedAt: FirestoreValueParsers.dateTime(data['updated_at']),
      isActive: FirestoreValueParsers.boolean(
        data['is_active'],
        fallback: true,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'display_name': displayName,
      'email': email,
      'role': role.value,
      'is_active': isActive,
      'created_at': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
