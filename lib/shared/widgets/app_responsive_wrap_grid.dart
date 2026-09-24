import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppResponsiveWrapGrid extends StatelessWidget {
  const AppResponsiveWrapGrid({
    super.key,
    required this.children,
    this.minItemWidth = 280,
    this.maxColumns = 4,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final proposedColumns =
            ((availableWidth + spacing) / (minItemWidth + spacing)).floor();
        final columnCount = math.min(
          children.length,
          proposedColumns.clamp(1, maxColumns),
        );
        final itemWidth = columnCount == 1
            ? availableWidth
            : (availableWidth - (spacing * (columnCount - 1))) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth.clamp(0, availableWidth),
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
