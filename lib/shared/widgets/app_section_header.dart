import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.primaryStrong, AppColors.member],
            ),
            borderRadius: AppRadii.pill,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(letterSpacing: -0.2),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle!, style: theme.textTheme.bodyMedium),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldStack = trailing != null && constraints.maxWidth < 720;

          if (shouldStack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: AppSpacing.md),
                trailing!,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: trailing!,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
