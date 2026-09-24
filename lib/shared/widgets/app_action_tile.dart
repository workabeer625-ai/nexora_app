import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_status_badge.dart';
import 'app_surface_card.dart';

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    this.onPressed,
    this.badgeLabel,
    this.badgeColor,
    this.backgroundColor,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback? onPressed;
  final String? badgeLabel;
  final Color? badgeColor;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final resolvedIconBackground = iconBackground ?? AppColors.primarySoft;
    final resolvedIconColor = iconColor ?? AppColors.primaryStrong;
    final resolvedBadgeColor = badgeColor ?? AppColors.surfaceMuted;

    return AppSurfaceCard(
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: resolvedIconBackground,
                  borderRadius: AppRadii.medium,
                ),
                child: Icon(icon, color: resolvedIconColor),
              ),
              if (badgeLabel != null && badgeLabel!.trim().isNotEmpty) ...[
                const Spacer(),
                AppStatusBadge(
                  label: badgeLabel!,
                  backgroundColor: resolvedBadgeColor,
                  foregroundColor: AppColors.ink,
                  maxWidth: 140,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}
