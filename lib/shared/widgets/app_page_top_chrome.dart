import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_status_badge.dart';
import 'app_surface_card.dart';

class AppPageTopChrome extends StatelessWidget {
  const AppPageTopChrome({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.accentGradient,
    this.badges = const <Widget>[],
    this.action,
  });

  final String title;
  final String eyebrow;
  final List<Color> accentGradient;
  final List<Widget> badges;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      glow: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ChromeOrbButton(
                gradient: accentGradient,
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.xs),
                action!,
              ],
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: badges,
            ),
          ],
        ],
      ),
    );
  }
}

class AppPageTopAction extends StatelessWidget {
  const AppPageTopAction({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.gradient,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = _ChromeOrbButton(
      gradient: gradient,
      icon: icon,
      onPressed: onPressed,
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ChromeOrbButton extends StatelessWidget {
  const _ChromeOrbButton({
    required this.gradient,
    required this.icon,
    required this.onPressed,
  });

  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: AppRadii.medium,
        boxShadow: AppShadows.glow,
      ),
      child: SizedBox.square(
        dimension: 52,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

List<Widget> buildTopChromeBadges({
  required BuildContext context,
  required List<String> labels,
}) {
  return labels
      .where((label) => label.trim().isNotEmpty)
      .map(
        (label) => AppStatusBadge(
          label: label,
          backgroundColor: AppColors.surfaceMuted,
          foregroundColor: AppColors.ink,
          maxWidth: 148,
        ),
      )
      .toList(growable: false);
}
