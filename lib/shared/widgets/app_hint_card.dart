import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_brand_icon.dart';
import 'app_surface_card.dart';

class AppHintCard extends StatelessWidget {
  const AppHintCard({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.leadingWidget,
    this.accentColor,
    this.backgroundColor,
    this.action,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? leadingWidget;
  final Color? accentColor;
  final Color? backgroundColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final resolvedAccentColor = accentColor ?? AppColors.info;
    final resolvedBackgroundColor = backgroundColor ?? AppColors.infoSoft;
    final iconWidget =
        leadingWidget ??
        (icon != null
            ? Icon(icon, color: resolvedAccentColor)
            : const AppBrandIcon(size: 22));

    return AppSurfaceCard(
      glow: true,
      backgroundColor: resolvedBackgroundColor,
      borderColor: resolvedAccentColor.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      resolvedAccentColor.withValues(alpha: 0.18),
                      resolvedAccentColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: AppRadii.medium,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: iconWidget,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(alignment: AlignmentDirectional.centerStart, child: action!),
          ],
        ],
      ),
    );
  }
}
