import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../../shared/models/app_startup_state.dart';
import '../errors/app_exception.dart';
import '../utils/platform_utils.dart';

class FirebaseInitializer {
  const FirebaseInitializer();

  Future<AppStartupState> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            )
          : Firebase.app();

      return AppStartupState.connected(
        appName: app.name,
        projectId: app.options.projectId,
        showOnboarding: showOnboarding,
      );
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);
      return AppStartupState.unsupported(
        message:
            'Firebase is configured for Android and iOS in this project. '
            'Add platform-specific setup before running on ${PlatformUtils.currentPlatformLabel}.',
        platformLabel: PlatformUtils.currentPlatformLabel,
        showOnboarding: showOnboarding,
      );
    } on FirebaseException catch (error) {
      final prefs = await SharedPreferences.getInstance();
      final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);
      final exception = FirebaseSetupException.fromFirebaseException(error);
      return AppStartupState.failed(
        message: exception.message,
        details: exception.details,
        showOnboarding: showOnboarding,
      );
    } catch (error, stackTrace) {
      final prefs = await SharedPreferences.getInstance();
      final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);
      final exception = AppException(
        'Firebase initialization failed unexpectedly.',
        details: '$error\n$stackTrace',
      );

      return AppStartupState.failed(
        message: exception.message,
        details: exception.details,
        showOnboarding: showOnboarding,
      );
    }
  }
}
