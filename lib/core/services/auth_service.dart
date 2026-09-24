import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthService {
  FirebaseAuth get instance;

  User? get currentUser;

  Stream<User?> authStateChanges();

  Stream<User?> userChanges();

  Future<void> signOut();
}

final class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? instance})
    : _instance = instance ?? FirebaseAuth.instance;

  final FirebaseAuth _instance;

  @override
  FirebaseAuth get instance => _instance;

  @override
  User? get currentUser => _instance.currentUser;

  @override
  Stream<User?> authStateChanges() => _instance.authStateChanges();

  @override
  Stream<User?> userChanges() => _instance.userChanges();

  @override
  Future<void> signOut() => _instance.signOut();
}
