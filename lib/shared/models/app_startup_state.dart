enum AppStartupPhase { connected, unsupported, failed }

class AppStartupState {
  const AppStartupState._({
    required this.phase,
    required this.title,
    required this.message,
    this.appName,
    this.projectId,
    this.details,
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

  factory AppStartupState.unsupported(
      {required String message, bool showOnboarding = false}) {
    return AppStartupState._(
      phase: AppStartupPhase.unsupported,
      title: 'Firebase mobile setup detected',
      message: message,
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
  final bool showOnboarding;

  bool get isReady => phase == AppStartupPhase.connected;

  String get statusLabel {
    return switch (phase) {
      AppStartupPhase.connected => 'Connected',
      AppStartupPhase.unsupported => 'Mobile Only',
      AppStartupPhase.failed => 'Needs Attention',
    };
  }
}
