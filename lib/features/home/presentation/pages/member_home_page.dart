import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_plural.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/home_task_row.dart';
import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../workspaces/domain/entities/workspace.dart';

/// Member home: a compact greeting plus today's actual tasks.
///
/// Deliberately short: hero, task list, done. Full queue lives in My Tasks.
class MemberHomePage extends StatelessWidget {
  const MemberHomePage({
    super.key,
    required this.userId,
    required this.selectedWorkspace,
    required this.onOpenMyTasks,
    required this.onOpenWorkspaceTab,
    this.topHeader,
  });

  final String userId;
  final Workspace? selectedWorkspace;
  final VoidCallback onOpenMyTasks;
  final VoidCallback onOpenWorkspaceTab;
  final Widget? topHeader;

  @override
  Widget build(BuildContext context) {
    final workspace = selectedWorkspace;
    if (workspace == null) {
      return AppEmptyState(
        title: context.tr(en: 'Start with a workspace', ar: 'ابدأ بمساحة عمل'),
        message: context.tr(
          en: 'Create your first workspace or join one with a code.',
          ar: 'أنشئ أول مساحة عمل أو انضم إلى واحدة عبر كود.',
        ),
        icon: Icons.workspaces_outline,
        action: FilledButton.icon(
          onPressed: onOpenWorkspaceTab,
          icon: const Icon(Icons.add_business_rounded),
          label: Text(context.tr(en: 'Open workspace', ar: 'فتح المساحة')),
        ),
      );
    }

    final services = AppScope.of(context);

    void openWorkspaceChat() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceChatPage(
            currentUserId: userId,
            workspace: workspace,
            canAccess: true,
            canModerate: false,
          ),
        ),
      );
    }

    void openTask(TaskItem task) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailPage(
            userId: userId,
            workspaceId: workspace.id,
            projectId: task.projectId,
            taskId: task.id,
          ),
        ),
      );
    }

    return StreamBuilder<List<TaskItem>>(
      stream: services.taskRepository.watchAssignedWorkspaceTasks(
        workspace.id,
        userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading your tasks...',
              ar: 'يتم تحميل مهامك...',
            ),
          );
        }

        final tasks = snapshot.data ?? const <TaskItem>[];
        final openTasks = tasks
            .where((task) => task.status != TaskStatus.done)
            .toList(growable: false);
        final doneCount = tasks.length - openTasks.length;
        final overdueCount = openTasks.where(_isOverdue).length;
        final dueSoonCount = openTasks
            .where((task) => !_isOverdue(task) && _isDueSoon(task))
            .length;

        final visible = openTasks.toList()
          ..sort((a, b) {
            final overdueOrder =
                (_isOverdue(a) ? 0 : 1) - (_isOverdue(b) ? 0 : 1);
            if (overdueOrder != 0) {
              return overdueOrder;
            }
            final dueA = a.dueDate;
            final dueB = b.dueDate;
            if (dueA == null && dueB == null) {
              return 0;
            }
            if (dueA == null) {
              return 1;
            }
            if (dueB == null) {
              return -1;
            }
            return dueA.compareTo(dueB);
          });

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            if (topHeader != null) ...[
              topHeader!,
              const SizedBox(height: AppSpacing.xl),
            ],
            _GreetingHero(
              workspaceName: workspace.name,
              openCount: openTasks.length,
              doneCount: doneCount,
              totalCount: tasks.length,
              overdueCount: overdueCount,
              dueSoonCount: dueSoonCount,
              onOpenMyTasks: onOpenMyTasks,
              onOpenChat: openWorkspaceChat,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(
                  context.tr(en: "Today's tasks", ar: 'مهام اليوم'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (openTasks.isNotEmpty)
                  TextButton(
                    onPressed: onOpenMyTasks,
                    child: Text(context.tr(en: 'View all', ar: 'عرض الكل')),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (openTasks.isEmpty)
              _EmptyTasksCard(onOpenWorkspace: onOpenWorkspaceTab)
            else
              ...visible
                  .take(5)
                  .map(
                    (task) => HomeTaskRow(
                      title: task.title,
                      caption: _captionFor(context, task),
                      dotColor: _dotColor(context, task),
                      badgeLabel:
                          task.priority == TaskPriority.high ||
                              task.priority == TaskPriority.urgent
                          ? context.tr(en: 'Urgent', ar: 'عاجل')
                          : null,
                      onTap: () => openTask(task),
                    ),
                  ),
          ],
        );
      },
    );
  }

  String _captionFor(BuildContext context, TaskItem task) {
    final due = task.dueDate;
    if (_isOverdue(task)) {
      return context.tr(
        en: 'Overdue · ${AppDateFormatter.shortDateLocalized(context, due)}',
        ar: 'متأخرة · ${AppDateFormatter.shortDateLocalized(context, due)}',
      );
    }
    if (due != null) {
      return context.tr(
        en: 'Due ${AppDateFormatter.shortDateLocalized(context, due)}',
        ar: 'الاستحقاق ${AppDateFormatter.shortDateLocalized(context, due)}',
      );
    }
    return task.status.localizedLabel(context);
  }

  Color _dotColor(BuildContext context, TaskItem task) {
    if (_isOverdue(task)) {
      return AppColors.error;
    }
    return switch (task.status) {
      TaskStatus.todo => AppColors.inkMuted,
      TaskStatus.inProgress => AppColors.info,
      TaskStatus.blocked => AppColors.error,
      TaskStatus.inReview => AppColors.warning,
      TaskStatus.done => AppColors.success,
    };
  }

  bool _isDueSoon(TaskItem task) {
    final dueDate = task.dueDate;
    if (dueDate == null || task.status == TaskStatus.done) {
      return false;
    }
    final difference = dueDate.difference(DateTime.now()).inDays;
    return difference >= 0 && difference <= 3;
  }

  bool _isOverdue(TaskItem task) {
    final dueDate = task.dueDate;
    if (dueDate == null || task.status == TaskStatus.done) {
      return false;
    }
    return dueDate.isBefore(DateTime.now());
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.workspaceName,
    required this.openCount,
    required this.doneCount,
    required this.totalCount,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.onOpenMyTasks,
    required this.onOpenChat,
  });

  final String workspaceName;
  final int openCount;
  final int doneCount;
  final int totalCount;
  final int overdueCount;
  final int dueSoonCount;
  final VoidCallback onOpenMyTasks;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? context.tr(en: 'Good morning', ar: 'صباح الخير')
        : context.tr(en: 'Good evening', ar: 'مساء الخير');

    final summary = context.trCount(
      openCount,
      enOne: '{n} open task',
      enOther: '{n} open tasks',
      arZero: 'لا مهام مفتوحة',
      arOne: 'مهمة واحدة مفتوحة',
      arTwo: 'مهمتان مفتوحتان',
      arFew: '{n} مهام مفتوحة',
      arMany: '{n} مهمة مفتوحة',
    );

    String? alert;
    if (overdueCount > 0) {
      alert = context.tr(
        en: 'Overdue: $overdueCount',
        ar: 'متأخرة: $overdueCount',
      );
    } else if (dueSoonCount > 0) {
      alert = context.tr(
        en: 'Due soon: $dueSoonCount',
        ar: 'قريبة الاستحقاق: $dueSoonCount',
      );
    } else if (totalCount > 0 && openCount == 0) {
      alert = context.tr(en: 'All done!', ar: 'أنجزت كل مهامك!');
    }

    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;

    return AppSurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.memberHeroGradient,
          ),
          borderRadius: AppRadii.xLarge,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                workspaceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                alert == null ? summary : '$summary · $alert',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (totalCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadii.pill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.inkOnLight,
                      ),
                      onPressed: onOpenMyTasks,
                      icon: const Icon(Icons.task_alt_rounded),
                      label: Text(
                        context.tr(en: 'My tasks', ar: 'مهامي'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      onPressed: onOpenChat,
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(context.tr(en: 'Chat', ar: 'الدردشة')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTasksCard extends StatelessWidget {
  const _EmptyTasksCard({required this.onOpenWorkspace});

  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 44,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(en: 'No tasks today', ar: 'لا مهام اليوم'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              en: 'Enjoy a calm day, or check the workspace.',
              ar: 'استمتع بيوم هادئ، أو تابع المساحة.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: onOpenWorkspace,
            child: Text(context.tr(en: 'Open workspace', ar: 'فتح المساحة')),
          ),
        ],
      ),
    );
  }
}
