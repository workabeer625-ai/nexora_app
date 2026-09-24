import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_status_badge.dart';
import 'app_surface_card.dart';

/// Compact tappable task row used on the home pages.
///
/// Shows a status dot, title, one-line caption, an optional badge
/// (e.g. urgent), and a chevron. One tap opens the task.
class HomeTaskRow extends StatelessWidget {
  const HomeTaskRow({
    super.key,
    required this.title,
    required this.caption,
    required this.dotColor,
    required this.onTap,
    this.badgeLabel,
  });

  final String title;
  final String caption;
  final Color dotColor;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadii.large,
        onTap: onTap,
        child: AppSurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(
                  label: badgeLabel!,
                  backgroundColor: AppColors.errorSoft,
                  foregroundColor: AppColors.error,
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
