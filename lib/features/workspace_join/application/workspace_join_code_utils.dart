import 'dart:math';

import '../../../core/errors/app_exception.dart';

final class WorkspaceJoinCodeUtils {
  const WorkspaceJoinCodeUtils._();

  static const String _prefix = 'NEXORA_JOIN:';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String normalize(String rawValue) {
    final extracted = extractValue(rawValue);
    final normalized = extracted.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    if (normalized.length < 8 || normalized.length > 20) {
      throw const ValidationException('Enter a valid join code.');
    }

    return normalized;
  }

  static String extractValue(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Join code is required.');
    }

    final upper = trimmed.toUpperCase();
    if (upper.startsWith(_prefix)) {
      return trimmed.substring(_prefix.length);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final fromQuery = uri.queryParameters['code'];
      if (fromQuery != null && fromQuery.trim().isNotEmpty) {
        return fromQuery.trim();
      }
    }

    return trimmed;
  }

  static String formatForDisplay(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index += 1) {
      if (index > 0 && index % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(value[index]);
    }

    return buffer.toString();
  }

  static String buildQrPayload(String code) => '$_prefix$code';

  static String generateCode({int length = 12}) {
    final random = Random.secure();
    final buffer = StringBuffer();

    for (var index = 0; index < length; index += 1) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }

    return formatForDisplay(buffer.toString());
  }
}
