import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_plural.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/home_task_row.dart';
import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../workspace_join/domain/entities/workspace_join_request.dart'
    show WorkspaceJoinRequest, WorkspaceJoinRequestStatus;
import '../../../workspaces/domain/entities/workspace.dart';
import '../../../workspaces/presentation/pages/workspace_detail_page.dart';

/// Admin home: a compact overview of what needs attention.
///
/// Hero, attention list, mini stats, quick actions. Invite management
/// moved to Workspace > Team tab to keep this page short.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.userId,
    required this.selectedWorkspace,
    required this.onOpenWorkspaces,
    required this.onOpenRequests,
    this.topHeader,
  });

  final String userId;
  final Workspace? selectedWorkspace;
  final VoidCallback onOpenWorkspaces;
  final VoidCallback onOpenRequests;
  final Widget? topHeader;

  @override
  Widget build(BuildContext context) {
    final workspace = selectedWorkspace;
    if (workspace == null) {
      return AppEmptyState(
        title: context.tr(
          en: 'No admin workspace selected',
          ar: 'لا توجد مساحة إدارة محددة',
        ),
        message: context.tr(
          en: 'Pick or create a workspace to get started.',
          ar: 'اختر مساحة عمل أو أنشئ واحدة للبدء.',
        ),
        icon: Icons.admin_panel_settings_outlined,
        action: FilledButton.icon(
          onPressed: onOpenWorkspaces,
          icon: const Icon(Icons.workspaces_outline),
          label: Text(context.tr(en: 'Open workspaces', ar: 'فتح المساحات')),
        ),
      );
    }

    final services = AppScope.of(context);

    void openWorkspaceDetail({int initialTabIndex = 0}) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceDetailPage(
            userId: userId,
            workspaceId: workspace.id,
            initialTabIndex: initialTabIndex,
          ),
        ),
      );
    }

    void openWorkspaceChat() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceChatPage(
            currentUserId: userId,
            workspace: workspace,
            canAccess: true,
            canModerate: true,
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

    return StreamBuilder<List<WorkspaceJoinRequest>>(
      stream: services.workspaceJoinService.watchJoinRequests(workspace.id),
      builder: (context, requestsSnapshot) {
        if (requestsSnapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading overview...',
              ar: 'يتم تحميل النظرة العامة...',
            ),
          );
        }
        final requests =
            requestsSnapshot.data ?? const <WorkspaceJoinRequest>[];
        final pendingRequests = requests
            .where(
              (request) =>
                  request.status == WorkspaceJoinRequestStatus.pending,
            )
            .length;

        return StreamBuilder<List<TaskItem>>(
          stream: services.taskRepository.watchWorkspaceTasks(workspace.id),
          builder: (context, tasksSnapshot) {
            if (tasksSnapshot.connectionState == ConnectionState.waiting) {
              return AppLoadingState(
                message: context.tr(
                  en: 'Loading overview...',
                  ar: 'يتم تحميل النظرة العامة...',
                ),
              );
            }
            final tasks = tasksSnapshot.data ?? const <TaskItem>[];
            final blockedTasks = tasks
                .where((task) => task.status == TaskStatus.blocked)
                .take(4)
                .toList(growable: false);
            final liveTasks = tasks
                .where((task) => task.status != TaskStatus.done)
                .length;

            return StreamBuilder<List<WorkspaceMember>>(
              stream: services.workspaceRepository.watchMembers(workspace.id),
              builder: (context, membersSnapshot) {
                if (membersSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return AppLoadingState(
                    message: context.tr(
                      en: 'Loading overview...',
                      ar: 'يتم تحميل النظرة العامة...',
                    ),
                  );
                }
                final members =
                    membersSnapshot.data ?? const <WorkspaceMember>[];
                final hasAttention =
                    pendingRequests > 0 || blockedTasks.isNotEmpty;

                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    if (topHeader != null) ...[
                      topHeader!,
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _AdminHero(
                      workspaceName: workspace.name,
                      pendingRequests: pendingRequests,
                      blockedCount: blockedTasks.length,
                      onReviewRequests: onOpenRequests,
                      onOpenChat: openWorkspaceChat,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      context.tr(
                        en: 'Needs your attention',
                        ar: 'يحتاج انتباهك',
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (!hasAttention)
                      _AllClearCard()
                    else ...[
                      if (pendingRequests > 0)
                        HomeTaskRow(
                          title: context.tr(
                            en: 'New join requests',
                            ar: 'طلبات انضمام جديدة',
                          ),
                          caption: context.trCount(
                            pendingRequests,
                            enOne: '{n} request waiting',
                            enOther: '{n} requests waiting',
                            arZero: 'لا طلبات بانتظار المراجعة',
                            arOne: 'طلب واحد بانتظار المراجعة',
                            arTwo: 'طلبان بانتظار المراجعة',
                            arFew: '{n} طلبات بانتظار المراجعة',
                            arMany: '{n} طلبًا بانتظار المراجعة',
                          ),
                          dotColor: AppColors.warning,
                          onTap: onOpenRequests,
                        ),
                      ...blockedTasks.map(
                        (task) => HomeTaskRow(
                          title: task.title,
                          caption:
                              task.blockedReason?.trim().isNotEmpty == true
                              ? task.blockedReason!.trim()
                              : context.tr(
                                  en: 'Blocked',
                                  ar: 'متوقفة',
                                ),
                          dotColor: AppColors.error,
                          badgeLabel:
                              task.priority == TaskPriority.high ||
                                  task.priority == TaskPriority.urgent
                              ? context.tr(en: 'Urgent', ar: 'عاجل')
                              : null,
                          onTap: () => openTask(task),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _MiniStatsCard(
                      memberCount: members.length,
                      pendingRequests: pendingRequests,
                      liveTasks: liveTasks,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: openWorkspaceDetail,
                          icon: const Icon(Icons.workspaces_outline),
                          label: Text(
                            context.tr(
                              en: 'Workspace',
                              ar: 'المساحة',
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => openWorkspaceDetail(
                            initialTabIndex: 1,
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            context.tr(
                              en: 'Invite members',
                              ar: 'دعوة أعضاء',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({
    required this.workspaceName,
    required this.pendingRequests,
    required this.blockedCount,
    required this.onReviewRequests,
    required this.onOpenChat,
  });

  final String workspaceName;
  final int pendingRequests;
  final int blockedCount;
  final VoidCallback onReviewRequests;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (pendingRequests > 0) {
      parts.add(
        context.trCount(
          pendingRequests,
          enOne: '{n} request waiting',
          enOther: '{n} requests waiting',
          arZero: 'لا طلبات بانتظار المراجعة',
          arOne: 'طلب واحد بانتظار المراجعة',
          arTwo: 'طلبان بانتظار المراجعة',
          arFew: '{n} طلبات بانتظار المراجعة',
          arMany: '{n} طلبًا بانتظار المراجعة',
        ),
      );
    }
    if (blockedCount > 0) {
      parts.add(
        context.tr(en: '$blockedCount blocked', ar: '$blockedCount متوقفة'),
      );
    }
    final summary = parts.isEmpty
        ? context.tr(en: 'Everything is under control.', ar: 'كل شيء تحت السيطرة.')
        : parts.join(' · ');

    return AppSurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.adminHeroGradient,
          ),
          borderRadius: AppRadii.xLarge,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workspaceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (pendingRequests > 0)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.inkOnLight,
                        ),
                        onPressed: onReviewRequests,
                        icon: const Icon(Icons.fact_check_outlined),
                        label: Text(
                          context.tr(
                            en: 'Review requests',
                            ar: 'مراجعة الطلبات',
                          ),
                        ),
                      ),
                    ),
                  if (pendingRequests > 0)
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

class _AllClearCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 40,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(en: 'Nothing pending', ar: 'لا شيء معلق'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(
                    en: 'Requests and blocked work are all clear.',
                    ar: 'الطلبات والمهام المتوقفة كلها واضحة.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatsCard extends StatelessWidget {
  const _MiniStatsCard({
    required this.memberCount,
    required this.pendingRequests,
    required this.liveTasks,
  });

  final int memberCount;
  final int pendingRequests;
  final int liveTasks;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          _Stat(
            value: '$memberCount',
            label: context.tr(en: 'Members', ar: 'الأعضاء'),
          ),
          _Stat(
            value: '$pendingRequests',
            label: context.tr(en: 'Pending', ar: 'معلقة'),
          ),
          _Stat(
            value: '$liveTasks',
            label: context.tr(en: 'Active tasks', ar: 'مهام جارية'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
