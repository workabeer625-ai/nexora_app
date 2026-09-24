import '../entities/user_profile.dart';

abstract interface class UserProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);

  Future<UserProfile?> fetchProfile(String uid);

  Future<void> createProfile(UserProfile profile);

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });
}
