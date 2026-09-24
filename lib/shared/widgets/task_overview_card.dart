import 'package:flutter/material.dart';

import '../../core/localization/app_domain_localizations.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/tasks/domain/entities/task_item.dart';
import 'app_status_badge.dart';
import 'app_surface_card.dart';

class TaskOverviewCard extends StatelessWidget {
  const TaskOverviewCard({
    super.key,
    required this.task,
    this.projectName,
    this.onTap,
    this.compact = false,
  });

  final TaskItem task;
  final String? projectName;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (projectName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(projectName!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatusBadge(
              label: '${task.progress}%',
              backgroundColor: AppColors.surfaceMuted,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            AppStatusBadge(
              label: task.status.localizedLabel(context),
              backgroundColor: _statusColor(task.status),
              foregroundColor: _statusForeground(task.status),
            ),
            AppStatusBadge(
              label: task.priority.localizedLabel(context),
              backgroundColor: _priorityColor(task.priority),
              foregroundColor: _priorityForeground(task.priority),
            ),
            if (task.reviewStatus != ReviewStatus.none)
              AppStatusBadge(
                label: task.reviewStatus.localizedLabel(context),
                backgroundColor: AppColors.infoSoft,
                foregroundColor: AppColors.info,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          task.description.isEmpty
              ? context.tr(
                  en: 'No description provided yet.',
                  ar: 'لا يوجد وصف بعد.',
                )
              : task.description,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _Meta(
              label: context.tr(en: 'Due', ar: 'الموعد'),
              value: AppDateFormatter.shortDate(task.dueDate),
            ),
            _Meta(
              label: context.tr(en: 'Assignee', ar: 'المكلّف'),
              value: task.assignedTo ??
                  context.tr(en: 'Unassigned', ar: 'غير مكلّف'),
            ),
          ],
        ),
      ],
    );

    final card = AppSurfaceCard(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      child: content,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: AppRadii.large,
      onTap: onTap,
      child: card,
    );
  }

  Color _statusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => AppColors.surfaceMuted,
      TaskStatus.inProgress => AppColors.infoSoft,
      TaskStatus.blocked => AppColors.errorSoft,
      TaskStatus.inReview => AppColors.warningSoft,
      TaskStatus.done => AppColors.successSoft,
    };
  }

  Color _statusForeground(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => AppColors.ink,
      TaskStatus.inProgress => AppColors.info,
      TaskStatus.blocked => AppColors.error,
      TaskStatus.inReview => AppColors.warning,
      TaskStatus.done => AppColors.success,
    };
  }

  Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => AppColors.surfaceMuted,
      TaskPriority.medium => AppColors.primarySoft,
      TaskPriority.high => AppColors.warningSoft,
      TaskPriority.urgent => AppColors.errorSoft,
    };
  }

  Color _priorityForeground(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => AppColors.ink,
      TaskPriority.medium => AppColors.primary,
      TaskPriority.high => AppColors.warning,
      TaskPriority.urgent => AppColors.error,
    };
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
