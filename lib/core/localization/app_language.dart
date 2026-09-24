enum AppLanguagePreference { system, arabic, english }

extension AppLanguagePreferenceMapper on AppLanguagePreference {
  String get storageValue {
    return switch (this) {
      AppLanguagePreference.system => 'system',
      AppLanguagePreference.arabic => 'ar',
      AppLanguagePreference.english => 'en',
    };
  }

  static AppLanguagePreference fromStorageValue(String? value) {
    return switch (value) {
      'ar' => AppLanguagePreference.arabic,
      'en' => AppLanguagePreference.english,
      _ => AppLanguagePreference.system,
    };
  }
}
