import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

final class AppLocaleController extends ChangeNotifier {
  static const _storageKey = 'nexora.locale.preference';

  AppLanguagePreference _preference = AppLanguagePreference.system;

  AppLanguagePreference get preference => _preference;

  Locale? get locale {
    return switch (_preference) {
      AppLanguagePreference.system => null,
      AppLanguagePreference.arabic => const Locale('ar'),
      AppLanguagePreference.english => const Locale('en'),
    };
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_storageKey);
    final resolvedPreference = AppLanguagePreferenceMapper.fromStorageValue(
      storedValue,
    );

    if (resolvedPreference == _preference) {
      return;
    }

    _preference = resolvedPreference;
    notifyListeners();
  }

  Future<void> setPreference(AppLanguagePreference value) async {
    if (value == _preference) {
      return;
    }

    _preference = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, value.storageValue);
  }
}
