import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class StatusSectionItem {
  const StatusSectionItem({required this.label, required this.value});

  final String label;
  final String value;
}

class StatusSection extends StatelessWidget {
  const StatusSection({super.key, required this.title, required this.items});

  final String title;
  final List<StatusSectionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            ...items.indexed.expand((entry) {
              final index = entry.$1;
              final item = entry.$2;

              return [
                _StatusRow(item: item),
                if (index < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
              ];
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.item});

  final StatusSectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.ink,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
