import 'package:flutter/material.dart';

import '../../shared/models/app_startup_state.dart';

class StartupStatusPage extends StatelessWidget {
  const StartupStatusPage({super.key, required this.startupState});

  final AppStartupState startupState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (startupState.phase) {
      AppStartupPhase.connected => theme.colorScheme.primary,
      AppStartupPhase.unsupported => Colors.orange.shade700,
      AppStartupPhase.failed => theme.colorScheme.error,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      startupState.statusLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    startupState.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    startupState.message,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  if (startupState.details != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      startupState.details!,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
