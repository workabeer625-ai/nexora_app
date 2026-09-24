import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_model.dart';

final class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestoreService.document(FirestorePaths.user(uid));
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return UserProfileModel.fromSnapshot(snapshot);
    });
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    return UserProfileModel.fromSnapshot(snapshot);
  }

  @override
  Future<void> createProfile(UserProfile profile) {
    final model = UserProfileModel.fromEntity(profile);

    return _doc(profile.uid).set({
      ...model.toFirestore(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) {
    return _doc(uid).update({
      'display_name': displayName,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
