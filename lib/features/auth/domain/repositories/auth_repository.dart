import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> authStateChanges();

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
