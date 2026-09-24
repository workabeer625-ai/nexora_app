import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/app_startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupState = await AppStartup.initialize();

  runApp(NexoraApp(startupState: startupState));
}
