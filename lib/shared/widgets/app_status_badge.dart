import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor,
    this.leading,
    this.leadingWidget,
    this.maxWidth = 220,
  });

  final String label;
  final Color backgroundColor;
  final Color? foregroundColor;
  final IconData? leading;
  final Widget? leadingWidget;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedForegroundColor = foregroundColor ?? AppColors.ink;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.pill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingWidget != null || leading != null) ...[
                leadingWidget ??
                    Icon(leading, size: 16, color: resolvedForegroundColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: resolvedForegroundColor,
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
