import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.top,
    this.floatingActionButton,
    this.maxWidth = 1180,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? top;
  final Widget? floatingActionButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.pageGradient,
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.headlineMedium),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(subtitle!, style: theme.textTheme.bodyLarge),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null && actions!.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                  if (top != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    top!,
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
