import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemePreference(this.storageValue);

  final String storageValue;

  ThemeMode get themeMode {
    return switch (this) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
  }

  static AppThemePreference fromStorageValue(String? value) {
    for (final preference in AppThemePreference.values) {
      if (preference.storageValue == value) {
        return preference;
      }
    }

    return AppThemePreference.system;
  }
}

final class AppThemeController extends ChangeNotifier
    with WidgetsBindingObserver {
  AppThemeController() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _storageKey = 'nexora.theme.preference';

  AppThemePreference _preference = AppThemePreference.system;

  AppThemePreference get preference => _preference;
  ThemeMode get themeMode => _preference.themeMode;

  Brightness get effectiveBrightness {
    return switch (_preference) {
      AppThemePreference.light => Brightness.light,
      AppThemePreference.dark => Brightness.dark,
      AppThemePreference.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_storageKey);
    final resolvedPreference = AppThemePreference.fromStorageValue(storedValue);

    if (resolvedPreference == _preference) {
      return;
    }

    _preference = resolvedPreference;
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference value) async {
    if (value == _preference) {
      return;
    }

    _preference = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, value.storageValue);
  }

  @override
  void didChangePlatformBrightness() {
    if (_preference == AppThemePreference.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
