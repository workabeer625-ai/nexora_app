import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  const AppException(this.message, {this.details});

  final String message;
  final String? details;

  @override
  String toString() => details == null ? message : '$message\n$details';
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.details});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.details});
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.details});
}

final class FirebaseSetupException extends AppException {
  const FirebaseSetupException(super.message, {super.details});

  factory FirebaseSetupException.fromFirebaseException(
    FirebaseException exception,
  ) {
    final detailParts = <String>[
      'plugin=${exception.plugin}',
      'code=${exception.code}',
      if (exception.message != null && exception.message!.trim().isNotEmpty)
        exception.message!.trim(),
    ];

    return FirebaseSetupException(
      'Firebase could not be initialized. Verify that the Android and iOS '
      'configuration files are present and registered correctly.',
      details: detailParts.join(' | '),
    );
  }
}
