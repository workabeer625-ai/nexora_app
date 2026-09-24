import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';

final class AppDateFormatter {
  const AppDateFormatter._();

  static String shortDate(DateTime? value) {
    if (value == null) {
      return 'Not set';
    }

    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '${local.year}-$month-$day';
  }

  static String dateTime(DateTime? value) {
    if (value == null) {
      return 'Not set';
    }

    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.year}-$month-$day $hour:$minute';
  }

  /// Localized variant: shows `غير محدد` instead of `Not set`
  /// when the app runs in Arabic.
  static String shortDateLocalized(BuildContext context, DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).isArabic ? 'غير محدد' : 'Not set';
    }

    return shortDate(value);
  }

  /// Localized variant: shows `غير محدد` instead of `Not set`
  /// when the app runs in Arabic.
  static String dateTimeLocalized(BuildContext context, DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).isArabic ? 'غير محدد' : 'Not set';
    }

    return dateTime(value);
  }
}
