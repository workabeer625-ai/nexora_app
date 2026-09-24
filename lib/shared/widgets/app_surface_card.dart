import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.backgroundColor,
    this.borderColor,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                (backgroundColor ?? AppColors.surfaceGlassStrong),
                (backgroundColor ?? AppColors.surfaceGlass)
                    .withValues(alpha: 0.92),
              ],
            ),
            borderRadius: AppRadii.large,
            border: Border.all(color: borderColor ?? AppColors.outlineStrong),
            boxShadow: glow
                ? <BoxShadow>[...AppShadows.soft, ...AppShadows.glow]
                : AppShadows.soft,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
