import 'package:cloud_firestore/cloud_firestore.dart';

final class FirestoreValueParsers {
  const FirestoreValueParsers._();

  static DateTime? dateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String string(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  static bool boolean(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    return fallback;
  }

  static int integer(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }

  static List<String> stringList(dynamic value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return const <String>[];
  }
}
