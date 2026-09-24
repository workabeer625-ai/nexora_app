import '../errors/app_exception.dart';

final class InputValidators {
  const InputValidators._();

  static String validateRequiredText(
    String value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 500,
  }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ValidationException('$fieldName is required.');
    }

    if (trimmed.length < minLength) {
      throw ValidationException(
        '$fieldName must be at least $minLength characters.',
      );
    }

    if (trimmed.length > maxLength) {
      throw ValidationException(
        '$fieldName must be at most $maxLength characters.',
      );
    }

    return trimmed;
  }

  static String validateEmail(String value) {
    final email = value.trim().toLowerCase();
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!regex.hasMatch(email)) {
      throw const ValidationException('Enter a valid email address.');
    }

    return email;
  }

  static String validatePassword(String value) {
    if (value.length < 8) {
      throw const ValidationException(
        'Password must be at least 8 characters.',
      );
    }

    return value;
  }

  static String validateUid(String value, {String fieldName = 'User ID'}) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ValidationException('$fieldName is required.');
    }

    if (trimmed.length < 6) {
      throw ValidationException('$fieldName looks invalid.');
    }

    return trimmed;
  }

  static int validateProgress(int value) {
    if (value < 0 || value > 100) {
      throw const ValidationException('Progress must be between 0 and 100.');
    }

    return value;
  }

  static void validateDateRange(DateTime? startDate, DateTime? dueDate) {
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      throw const ValidationException(
        'Due date cannot be earlier than start date.',
      );
    }
  }
}
