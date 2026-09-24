import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppFloatingNavDestination {
  const AppFloatingNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppFloatingNavBar extends StatelessWidget {
  const AppFloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AppFloatingNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.xLarge,
        border: Border.all(color: AppColors.navStroke),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navSurface, AppColors.surfaceGlassStrong],
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            for (int index = 0; index < destinations.length; index++)
              Expanded(
                child: _NavItem(
                  destination: destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelect(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppFloatingNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: AppRadii.large,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.primaryStrong,
                  AppColors.primary,
                  AppColors.member,
                ],
              )
            : null,
        boxShadow: selected ? AppShadows.glow : null,
      ),
      child: InkWell(
        borderRadius: AppRadii.large,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: selected ? Colors.white : AppColors.inkMuted,
                size: selected ? 24 : 22,
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: (theme.textTheme.labelSmall ?? const TextStyle())
                    .copyWith(
                      color: selected ? Colors.white : AppColors.inkMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: AppRadii.pill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
