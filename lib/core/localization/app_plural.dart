import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Arabic-aware counter localization.
///
/// Arabic uses different noun forms depending on the count:
/// zero, one, two, few (3-10) and many (11+).
/// English only needs one/other.
///
/// Every template may contain `{n}` which is replaced with [count].
final class AppPlural {
  const AppPlural._();

  static String count(
    BuildContext context,
    int count, {
    required String enOne,
    required String enOther,
    required String arZero,
    required String arOne,
    required String arTwo,
    required String arFew,
    required String arMany,
  }) {
    final safeCount = count < 0 ? 0 : count;
    final isArabic = AppLocalizations.of(context).isArabic;

    if (!isArabic) {
      final template = safeCount == 1 ? enOne : enOther;
      return template.replaceAll('{n}', '$safeCount');
    }

    final template = switch (safeCount) {
      0 => arZero,
      1 => arOne,
      2 => arTwo,
      >= 3 && <= 10 => arFew,
      _ => arMany,
    };
    return template.replaceAll('{n}', '$safeCount');
  }
}

extension PluralContext on BuildContext {
  String trCount(
    int count, {
    required String enOne,
    required String enOther,
    required String arZero,
    required String arOne,
    required String arTwo,
    required String arFew,
    required String arMany,
  }) {
    return AppPlural.count(
      this,
      count,
      enOne: enOne,
      enOther: enOther,
      arZero: arZero,
      arOne: arOne,
      arTwo: arTwo,
      arFew: arFew,
      arMany: arMany,
    );
  }
}
