import '../../shared/models/app_startup_state.dart';
import 'firebase_initializer.dart';

final class AppStartup {
  const AppStartup._();

  static Future<AppStartupState> initialize({
    FirebaseInitializer initializer = const FirebaseInitializer(),
  }) {
    return initializer.initialize();
  }
}
