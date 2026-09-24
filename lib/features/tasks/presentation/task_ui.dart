import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/entities/task_item.dart';

Color taskStatusTint(TaskStatus status) {
  return switch (status) {
    TaskStatus.todo => AppColors.surfaceMuted,
    TaskStatus.inProgress => AppColors.infoSoft,
    TaskStatus.blocked => AppColors.errorSoft,
    TaskStatus.inReview => AppColors.warningSoft,
    TaskStatus.done => AppColors.successSoft,
  };
}

Color taskStatusForeground(TaskStatus status) {
  return switch (status) {
    TaskStatus.todo => AppColors.ink,
    TaskStatus.inProgress => AppColors.info,
    TaskStatus.blocked => AppColors.error,
    TaskStatus.inReview => AppColors.warning,
    TaskStatus.done => AppColors.success,
  };
}

IconData taskStatusIcon(TaskStatus status) {
  return switch (status) {
    TaskStatus.todo => Icons.radio_button_unchecked_rounded,
    TaskStatus.inProgress => Icons.timelapse_rounded,
    TaskStatus.blocked => Icons.block_rounded,
    TaskStatus.inReview => Icons.fact_check_outlined,
    TaskStatus.done => Icons.check_circle_outline_rounded,
  };
}

Color taskPriorityTint(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.low => AppColors.surfaceMuted,
    TaskPriority.medium => AppColors.primarySoft,
    TaskPriority.high => AppColors.warningSoft,
    TaskPriority.urgent => AppColors.errorSoft,
  };
}

Color taskPriorityForeground(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.low => AppColors.ink,
    TaskPriority.medium => AppColors.primary,
    TaskPriority.high => AppColors.warning,
    TaskPriority.urgent => AppColors.error,
  };
}

IconData taskPriorityIcon(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.low => Icons.south_east_rounded,
    TaskPriority.medium => Icons.remove_rounded,
    TaskPriority.high => Icons.north_rounded,
    TaskPriority.urgent => Icons.priority_high_rounded,
  };
}

Color reviewStatusTint(ReviewStatus status) {
  return switch (status) {
    ReviewStatus.none => AppColors.surfaceMuted,
    ReviewStatus.pending => AppColors.warningSoft,
    ReviewStatus.approved => AppColors.successSoft,
    ReviewStatus.rejected => AppColors.errorSoft,
  };
}

Color reviewStatusForeground(ReviewStatus status) {
  return switch (status) {
    ReviewStatus.none => AppColors.ink,
    ReviewStatus.pending => AppColors.warning,
    ReviewStatus.approved => AppColors.success,
    ReviewStatus.rejected => AppColors.error,
  };
}

bool isTaskOverdue(TaskItem task) {
  final dueDate = task.dueDate;
  if (dueDate == null || task.status == TaskStatus.done) {
    return false;
  }

  return dueDate.isBefore(DateTime.now());
}

bool isTaskDueSoon(TaskItem task, {int days = 3}) {
  final dueDate = task.dueDate;
  if (dueDate == null || task.status == TaskStatus.done) {
    return false;
  }

  final now = DateTime.now();
  final windowEnd = now.add(Duration(days: days));
  return dueDate.isAfter(now) && dueDate.isBefore(windowEnd);
}

String compactUserLabel(String? userId, {String fallback = 'Unassigned'}) {
  if (userId == null || userId.trim().isEmpty) {
    return fallback;
  }

  final value = userId.trim();
  if (value.length <= 14) {
    return value;
  }

  return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
}
