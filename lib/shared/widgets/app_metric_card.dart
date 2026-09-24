import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_surface_card.dart';

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.tintColor,
    this.iconColor,
    this.trailing,
    this.glow = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final Color? tintColor;
  final Color? iconColor;
  final Widget? trailing;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTintColor = tintColor ?? AppColors.primarySoft;
    final resolvedIconColor = iconColor ?? AppColors.primary;

    return AppSurfaceCard(
      glow: glow,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      resolvedTintColor,
                      resolvedTintColor.withValues(alpha: 0.52),
                    ],
                  ),
                  borderRadius: AppRadii.medium,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: resolvedIconColor),
                ),
              ),
              const Spacer(),
              trailing ??
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: resolvedIconColor.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(caption!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadii.pill,
            child: LinearProgressIndicator(
              value: 1,
              minHeight: 5,
              color: resolvedIconColor.withValues(alpha: 0.72),
              backgroundColor: resolvedTintColor.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
