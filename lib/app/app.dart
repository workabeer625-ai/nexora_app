import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/onboarding/presentation/pages/onboarding_page.dart';
import 'app_scope.dart';
import '../core/localization/app_locale_controller.dart';
import '../core/localization/app_locale_scope.dart';
import '../core/localization/app_localizations.dart';
import 'pages/app_shell_page.dart';
import 'pages/startup_status_page.dart';
import '../core/constants/app_constants.dart';
import '../core/services/app_services.dart';
import '../core/theme/app_theme_controller.dart';
import '../core/theme/app_theme_scope.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../shared/models/app_startup_state.dart';

class NexoraApp extends StatefulWidget {
  const NexoraApp({super.key, required this.startupState});

  final AppStartupState startupState;

  @override
  State<NexoraApp> createState() => _NexoraAppState();
}

class _NexoraAppState extends State<NexoraApp> {
  late final AppLocaleController _localeController;
  late final AppThemeController _themeController;
  late final AppServices? _appServices;

  @override
  void initState() {
    super.initState();
    _localeController = AppLocaleController()..load();
    _themeController = AppThemeController()..load();
    _appServices = widget.startupState.isReady ? AppServices() : null;
  }

  @override
  void dispose() {
    _localeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AnimatedBuilder(
      animation: Listenable.merge([_localeController, _themeController]),
      builder: (context, _) {
        AppColors.applyBrightness(_themeController.effectiveBrightness);

        final materialApp = MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeController.themeMode,
          locale: _localeController.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget.startupState.showOnboarding
              ? const OnboardingPage()
              : widget.startupState.isReady && _appServices != null
                  ? const AppShellPage()
                  : StartupStatusPage(startupState: widget.startupState),
        );

        if (widget.startupState.isReady && _appServices != null) {
          return AppScope(services: _appServices, child: materialApp);
        }

        return materialApp;
      },
    );

    return AppThemeScope(
      controller: _themeController,
      child: AppLocaleScope(controller: _localeController, child: app),
    );
  }
}
