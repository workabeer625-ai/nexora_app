import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

final class FirebaseEmailAuthRepository implements AuthRepository {
  FirebaseEmailAuthRepository({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  FirebaseAuth get _instance => _authService.instance;

  @override
  User? get currentUser => _authService.currentUser;

  @override
  Stream<User?> authStateChanges() => _authService.authStateChanges();

  @override
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => _authService.signOut();
}
