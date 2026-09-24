import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_app/app/app.dart';
import 'package:nexora_app/shared/models/app_startup_state.dart';

void main() {
  testWidgets('renders startup status when Firebase app is not bootstrapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      NexoraApp(
        startupState: AppStartupState.connected(
          appName: '[DEFAULT]',
          projectId: 'nexora-test-project',
        ),
      ),
    );

    expect(find.text('Firebase connected successfully'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
  });
}
