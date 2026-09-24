import 'package:flutter/widgets.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/localization/app_localizations.dart';

enum AppStartupPhase { connected, unsupported, failed }

class AppStartupState {
  const AppStartupState._({
    required this.phase,
    required this.title,
    required this.message,
    this.appName,
    this.projectId,
    this.details,
    this.platformLabel = '',
    this.showOnboarding = false,
  });

  factory AppStartupState.connected({
    required String appName,
    String? projectId,
    bool showOnboarding = false,
  }) {
    return AppStartupState._(
      phase: AppStartupPhase.connected,
      title: 'Firebase connected successfully',
      message:
          'The native Firebase SDKs are initialized and the base service layer '
          'is ready for authentication, Firestore, and Storage features.',
      appName: appName,
      projectId: projectId,
      showOnboarding: showOnboarding,
    );
  }

  factory AppStartupState.unsupported({
    required String message,
    String platformLabel = '',
    bool showOnboarding = false,
  }) {
    return AppStartupState._(
      phase: AppStartupPhase.unsupported,
      title: 'Firebase mobile setup detected',
      message: message,
      platformLabel: platformLabel,
      showOnboarding: showOnboarding,
    );
  }

  factory AppStartupState.failed(
      {required String message, String? details, bool showOnboarding = false}) {
    return AppStartupState._(
      phase: AppStartupPhase.failed,
      title: 'Firebase startup failed',
      message: message,
      details: details,
      showOnboarding: showOnboarding,
    );
  }

  final AppStartupPhase phase;
  final String title;
  final String message;
  final String? appName;
  final String? projectId;
  final String? details;
  final String platformLabel;
  final bool showOnboarding;

  bool get isReady => phase == AppStartupPhase.connected;

  String get statusLabel {
    return switch (phase) {
      AppStartupPhase.connected => 'Connected',
      AppStartupPhase.unsupported => 'Mobile Only',
      AppStartupPhase.failed => 'Needs Attention',
    };
  }

  String statusLabelL10n(BuildContext context) {
    return switch (phase) {
      AppStartupPhase.connected => context.tr(en: 'Connected', ar: 'متصل'),
      AppStartupPhase.unsupported =>
        context.tr(en: 'Mobile Only', ar: 'للجوال فقط'),
      AppStartupPhase.failed =>
        context.tr(en: 'Needs Attention', ar: 'يحتاج إلى انتباه'),
    };
  }

  String titleL10n(BuildContext context) {
    return switch (phase) {
      AppStartupPhase.connected => context.tr(
          en: 'Firebase connected successfully',
          ar: 'تم الاتصال بـ Firebase بنجاح',
        ),
      AppStartupPhase.unsupported => context.tr(
          en: 'Firebase mobile setup detected',
          ar: 'تم رصد إعداد Firebase للجوال',
        ),
      AppStartupPhase.failed => context.tr(
          en: 'Firebase startup failed',
          ar: 'فشل بدء تشغيل Firebase',
        ),
    };
  }

  String messageL10n(BuildContext context) {
    switch (phase) {
      case AppStartupPhase.connected:
        return context.tr(
          en: 'The native Firebase SDKs are initialized and the base service layer '
              'is ready for authentication, Firestore, and Storage features.',
          ar: 'تمت تهيئة حزم Firebase الأصلية، وطبقة الخدمات الأساسية جاهزة '
              'للمصادقة وقاعدة البيانات والتخزين.',
        );
      case AppStartupPhase.unsupported:
        if (platformLabel.isEmpty) {
          return message;
        }
        return context.tr(
          en: 'Firebase is configured for Android and iOS in this project. '
              'Add platform-specific setup before running on $platformLabel.',
          ar: 'تمت تهيئة Firebase لنظامي Android وiOS في هذا المشروع. '
              'أضف إعدادًا خاصًا بالمنصة قبل التشغيل على $platformLabel.',
        );
      case AppStartupPhase.failed:
        return context.trError(AppException(message));
    }
  }
}
