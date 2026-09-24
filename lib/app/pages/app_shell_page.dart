import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/errors/error_messages.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_state.dart';
import '../../features/workspace_join/presentation/pages/guest_landing_page.dart';
import '../app_scope.dart';
import 'home_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<User?>(
      stream: services.authCoordinator.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppLoadingState(
              message: context.tr(
                en: 'Checking your session...',
                ar: 'يتم التحقق من جلستك...',
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const GuestLandingPage();
        }

        return _AuthenticatedGate(user: user);
      },
    );
  }
}

class _AuthenticatedGate extends StatelessWidget {
  const _AuthenticatedGate({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return FutureBuilder<void>(
      future: services.authCoordinator.ensureProfile(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: AppLoadingState(
              message: context.tr(
                en: 'Loading your workspace...',
                ar: 'يتم تحميل مساحة العمل...',
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(
              message: context.trError(snapshot.error),
            ),
          );
        }

        return HomePage(user: user);
      },
    );
  }
}
