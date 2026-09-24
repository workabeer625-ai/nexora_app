import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/validators/input_validators.dart';
import '../../users/domain/entities/user_profile.dart';
import '../../users/domain/repositories/user_profile_repository.dart';
import '../domain/repositories/auth_repository.dart';

final class AuthCoordinator {
  AuthCoordinator({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
  }) : _authRepository = authRepository,
       _userProfileRepository = userProfileRepository;

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  Stream<User?> authStateChanges() => _authRepository.authStateChanges();

  User? get currentUser => _authRepository.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final normalizedEmail = InputValidators.validateEmail(email);
      final normalizedPassword = InputValidators.validatePassword(password);
      final normalizedDisplayName = InputValidators.validateRequiredText(
        displayName,
        fieldName: 'Display name',
        minLength: 2,
        maxLength: 60,
      );

      final credential = await _authRepository.signUpWithEmailPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      final user = credential.user;

      if (user == null) {
        throw const AppException(
          'Authentication succeeded but no user was returned.',
        );
      }

      await _userProfileRepository.createProfile(
        UserProfile(
          uid: user.uid,
          displayName: normalizedDisplayName,
          email: normalizedEmail,
          role: UserRoleMapper.fromValue(AppConstants.defaultUserRole),
          isActive: true,
        ),
      );
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final normalizedEmail = InputValidators.validateEmail(email);
      final normalizedPassword = InputValidators.validatePassword(password);

      final credential = await _authRepository.signInWithEmailPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      final user = credential.user;

      if (user == null) {
        throw const AppException(
          'Authentication succeeded but no user was returned.',
        );
      }

      await ensureProfile(user);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> ensureProfile(User user) async {
    final existingProfile = await _userProfileRepository.fetchProfile(user.uid);
    if (existingProfile != null) {
      return;
    }

    final fallbackDisplayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'Nexora User');

    await _userProfileRepository.createProfile(
      UserProfile(
        uid: user.uid,
        displayName: fallbackDisplayName,
        email: user.email ?? '',
        role: UserRoleMapper.fromValue(AppConstants.defaultUserRole),
        isActive: true,
      ),
    );
  }

  Future<void> signOut() => _authRepository.signOut();

  AppException _mapFirebaseAuthError(FirebaseAuthException error) {
    final rawMessage = error.message ?? '';

    if (error.code == 'unknown' &&
        rawMessage.contains('CONFIGURATION_NOT_FOUND')) {
      return const AppException(
        'Firebase Authentication is not fully configured for Email/Password. '
        'Enable Email/Password in Firebase Console > Authentication > Sign-in method.',
      );
    }

    return switch (error.code) {
      'email-already-in-use' => const ValidationException(
        'This email is already registered.',
      ),
      'invalid-email' => const ValidationException(
        'Enter a valid email address.',
      ),
      'weak-password' => const ValidationException('Password is too weak.'),
      'invalid-credential' => const ValidationException(
        'Invalid email or password.',
      ),
      'wrong-password' => const ValidationException(
        'Invalid email or password.',
      ),
      'user-not-found' => const ValidationException(
        'No account exists for this email.',
      ),
      'too-many-requests' => const AppException(
        'Too many attempts. Please try again later.',
      ),
      _ => AppException(
        rawMessage.isEmpty ? 'Authentication failed.' : rawMessage,
      ),
    };
  }
}
