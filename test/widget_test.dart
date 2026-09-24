import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_app/app/app.dart';
import 'package:nexora_app/shared/models/app_startup_state.dart';

void main() {
  testWidgets('renders startup status when Firebase app is not bootstrapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      NexoraApp(
        startupState: AppStartupState.failed(
          message: 'Firebase initialization failed unexpectedly.',
        ),
      ),
    );

    expect(find.text('Firebase startup failed'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
  });
}
