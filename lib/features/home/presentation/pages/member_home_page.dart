import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_action_tile.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_metric_card.dart';
import '../../../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../../workspaces/presentation/pages/workspace_detail_page.dart';

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
    if (selectedWorkspace == null) {
      return AppEmptyState(
        title: context.tr(en: 'Start with a workspace', ar: 'ابدأ بمساحة عمل'),
        message: context.tr(
          en: 'Create your first workspace or join one with a code. Once you do, Nexora will organize your daily work around it.',
          ar: 'أنشئ أول مساحة عمل أو انضم إلى واحدة عبر كود. وبعد ذلك سينظم Nexora عملك اليومي حولها.',
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
    final workspace = selectedWorkspace!;

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
            canModerate: false,
          ),
        ),
      );
    }

    return StreamBuilder<List<Project>>(
      stream: services.projectRepository.watchProjects(workspace.id),
      builder: (context, projectsSnapshot) {
        if (projectsSnapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading workspace intelligence...',
              ar: 'يتم تحميل ذكاء مساحة العمل...',
            ),
          );
        }

        final projects = projectsSnapshot.data ?? const <Project>[];

        return StreamBuilder<List<TaskItem>>(
          stream: services.taskRepository.watchAssignedWorkspaceTasks(
            workspace.id,
            userId,
          ),
          builder: (context, assignedSnapshot) {
            if (assignedSnapshot.connectionState == ConnectionState.waiting) {
              return AppLoadingState(
                message: context.tr(
                  en: 'Loading your task intelligence...',
                  ar: 'يتم تحميل ذكاء مهامك...',
                ),
              );
            }

            final assignedTasks = assignedSnapshot.data ?? const <TaskItem>[];

            return StreamBuilder<List<TaskItem>>(
              stream: services.taskRepository.watchWorkspaceTasks(workspace.id),
              builder: (context, workspaceTasksSnapshot) {
                if (workspaceTasksSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return AppLoadingState(
                    message: context.tr(
                      en: 'Loading workspace signals...',
                      ar: 'يتم تحميل إشارات المساحة...',
                    ),
                  );
                }

                final workspaceTasks =
                    workspaceTasksSnapshot.data ?? const <TaskItem>[];

                final dueSoon = assignedTasks.where(_isDueSoon).length;
                final overdue = assignedTasks.where(_isOverdue).length;
                final inProgress = assignedTasks
                    .where((task) => task.status == TaskStatus.inProgress)
                    .length;
                final inReview = assignedTasks
                    .where((task) => task.status == TaskStatus.inReview)
                    .length;
                final completed = assignedTasks
                    .where((task) => task.status == TaskStatus.done)
                    .length;
                final blockedWorkspace = workspaceTasks
                    .where((task) => task.status == TaskStatus.blocked)
                    .length;
                final activeProjects = projects
                    .where((project) => project.status == ProjectStatus.active)
                    .length;

                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    if (topHeader != null) ...[
                      topHeader!,
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _MemberHero(
                      workspace: workspace,
                      activeProjects: activeProjects,
                      assignedTaskCount: assignedTasks.length,
                      onOpenWorkspace: openWorkspaceDetail,
                      onOpenChat: openWorkspaceChat,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppSectionHeader(
                      title: context.tr(
                        en: 'Next best actions',
                        ar: 'أفضل الإجراءات التالية',
                      ),
                      subtitle: context.tr(
                        en: 'Move from orientation into execution without digging through the product.',
                        ar: 'انتقل من الفهم السريع إلى التنفيذ دون البحث داخل المنتج.',
                      ),
                    ),
                    AppResponsiveWrapGrid(
                      minItemWidth: 300,
                      maxColumns: 3,
                      children: [
                        AppActionTile(
                          icon: Icons.task_alt_rounded,
                          title: context.tr(
                            en: 'Go to My Tasks',
                            ar: 'اذهب إلى مهامي',
                          ),
                          description: context.tr(
                            en: 'Open the raw execution queue, update status, and focus on what needs action now.',
                            ar: 'افتح صف التنفيذ المباشر، حدّث الحالات، وركّز على ما يحتاج إجراء الآن.',
                          ),
                          ctaLabel: context.tr(
                            en: 'Open my tasks',
                            ar: 'فتح مهامي',
                          ),
                          onPressed: onOpenMyTasks,
                          badgeLabel: context.tr(
                            en: 'Daily work',
                            ar: 'العمل اليومي',
                          ),
                          badgeColor: AppColors.memberSoft,
                          iconBackground: AppColors.memberSoft,
                          iconColor: AppColors.member,
                        ),
                        AppActionTile(
                          icon: Icons.workspaces_outline,
                          title: context.tr(
                            en: 'Open workspace context',
                            ar: 'افتح سياق المساحة',
                          ),
                          description: context.tr(
                            en: 'See projects, team context, and workspace chat without leaving your current orbit.',
                            ar: 'شاهد المشاريع وسياق الفريق وشات المساحة دون مغادرة مسارك الحالي.',
                          ),
                          ctaLabel: context.tr(
                            en: 'Open workspace',
                            ar: 'فتح المساحة',
                          ),
                          onPressed: onOpenWorkspaceTab,
                          badgeLabel: context.tr(
                            en: 'Team context',
                            ar: 'سياق الفريق',
                          ),
                          badgeColor: AppColors.infoSoft,
                          iconBackground: AppColors.infoSoft,
                          iconColor: AppColors.info,
                        ),
                        AppActionTile(
                          icon: Icons.arrow_outward_rounded,
                          title: context.tr(
                            en: 'Open full workspace view',
                            ar: 'فتح عرض المساحة الكامل',
                          ),
                          description: context.tr(
                            en: 'Jump directly into the detailed workspace surface when you need deeper context or team chat.',
                            ar: 'انتقل مباشرة إلى عرض المساحة التفصيلي عندما تحتاج سياقًا أعمق أو شات الفريق.',
                          ),
                          ctaLabel: context.tr(
                            en: 'Launch detail',
                            ar: 'فتح التفاصيل',
                          ),
                          onPressed: openWorkspaceDetail,
                          badgeLabel: context.tr(
                            en: 'Deep context',
                            ar: 'سياق أعمق',
                          ),
                          badgeColor: AppColors.primarySoft,
                        ),
                        AppActionTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: context.tr(
                            en: 'Open team chat',
                            ar: 'فتح دردشة الفريق',
                          ),
                          description: context.tr(
                            en: 'Go straight to the workspace chat when you need a quick handoff, answer, or team alignment.',
                            ar: 'ادخل مباشرة إلى دردشة الفريق عندما تحتاج ردًا سريعًا أو تنسيقًا مع الفريق.',
                          ),
                          ctaLabel: context.tr(
                            en: 'Open chat',
                            ar: 'فتح الدردشة',
                          ),
                          onPressed: openWorkspaceChat,
                          badgeLabel: context.tr(
                            en: 'Quick alignment',
                            ar: 'تنسيق سريع',
                          ),
                          badgeColor: AppColors.memberSoft,
                          iconBackground: AppColors.memberSoft,
                          iconColor: AppColors.member,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _MetricGrid(
                      children: [
                        AppMetricCard(
                          label: context.tr(
                            en: 'Assigned to you',
                            ar: 'المسندة إليك',
                          ),
                          value: '${assignedTasks.length}',
                          caption: context.tr(
                            en: 'Everything directly in your execution lane',
                            ar: 'كل ما يقع مباشرة في مسار تنفيذك',
                          ),
                          icon: Icons.assignment_ind_rounded,
                          tintColor: AppColors.memberSoft,
                          iconColor: AppColors.member,
                        ),
                        AppMetricCard(
                          label: context.tr(
                            en: 'Due soon',
                            ar: 'قريبة الاستحقاق',
                          ),
                          value: '$dueSoon',
                          caption: context.tr(
                            en: 'Needs attention before the day closes',
                            ar: 'تحتاج انتباهًا قبل نهاية اليوم',
                          ),
                          icon: Icons.event_available_outlined,
                          tintColor: AppColors.warningSoft,
                          iconColor: AppColors.warning,
                          glow: dueSoon > 0,
                        ),
                        AppMetricCard(
                          label: context.tr(
                            en: 'In review',
                            ar: 'قيد المراجعة',
                          ),
                          value: '$inReview',
                          caption: context.tr(
                            en: 'Work waiting on feedback or approval',
                            ar: 'عمل ينتظر الملاحظات أو الموافقة',
                          ),
                          icon: Icons.fact_check_outlined,
                          tintColor: AppColors.infoSoft,
                          iconColor: AppColors.info,
                        ),
                        AppMetricCard(
                          label: context.tr(
                            en: 'Workspace blockers',
                            ar: 'عوائق المساحة',
                          ),
                          value: '$blockedWorkspace',
                          caption: context.tr(
                            en: 'Signals that might slow the whole team',
                            ar: 'إشارات قد تبطئ الفريق بالكامل',
                          ),
                          icon: Icons.block_rounded,
                          tintColor: AppColors.errorSoft,
                          iconColor: AppColors.error,
                          glow: blockedWorkspace > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppSectionHeader(
                      title: context.tr(
                        en: 'Personal execution analytics',
                        ar: 'تحليلات تنفيذك الشخصي',
                      ),
                      subtitle: context.tr(
                        en: 'A focused read on your workload, timing, and delivery confidence.',
                        ar: 'قراءة مركزة لعبء عملك وتوقيته وثقة التسليم.',
                      ),
                    ),
                    _MetricGrid(
                      children: [
                        _SignalPanel(
                          title: context.tr(
                            en: 'Your task mix',
                            ar: 'مزيج مهامك',
                          ),
                          subtitle: context.tr(
                            en: 'How your current queue is distributed.',
                            ar: 'كيف يتوزع صف عملك الحالي.',
                          ),
                          bars: [
                            _SignalBarData(
                              label: context.tr(
                                en: 'In progress',
                                ar: 'قيد التنفيذ',
                              ),
                              count: inProgress,
                              color: AppColors.info,
                            ),
                            _SignalBarData(
                              label: context.tr(
                                en: 'In review',
                                ar: 'قيد المراجعة',
                              ),
                              count: inReview,
                              color: AppColors.warning,
                            ),
                            _SignalBarData(
                              label: context.tr(en: 'Completed', ar: 'مكتملة'),
                              count: completed,
                              color: AppColors.success,
                            ),
                            _SignalBarData(
                              label: context.tr(en: 'Overdue', ar: 'متأخرة'),
                              count: overdue,
                              color: AppColors.error,
                            ),
                          ],
                        ),
                        _SignalPanel(
                          title: context.tr(
                            en: 'Timing radar',
                            ar: 'رادار التوقيت',
                          ),
                          subtitle: context.tr(
                            en: 'What needs immediate focus and what remains stable.',
                            ar: 'ما يحتاج تركيزًا فوريًا وما يزال مستقرًا.',
                          ),
                          bars: [
                            _SignalBarData(
                              label: context.tr(
                                en: 'Due soon',
                                ar: 'قريبة الاستحقاق',
                              ),
                              count: dueSoon,
                              color: AppColors.warning,
                            ),
                            _SignalBarData(
                              label: context.tr(en: 'Overdue', ar: 'متأخرة'),
                              count: overdue,
                              color: AppColors.error,
                            ),
                            _SignalBarData(
                              label: context.tr(en: 'Stable', ar: 'مستقرة'),
                              count: (assignedTasks.length - dueSoon - overdue)
                                  .clamp(0, assignedTasks.length),
                              color: AppColors.member,
                            ),
                          ],
                        ),
                        AppSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  en: 'Today’s reading',
                                  ar: 'قراءة اليوم',
                                ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.tr(
                                  en: 'This home surface is now signal-only. Use My Tasks for the raw queue and keep this page for fast orientation.',
                                  ar: 'هذه الصفحة أصبحت معتمدة على الإشارات فقط. استخدم مهامي للصف الخام، واترك هذه الصفحة للتموضع السريع.',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _InsightLine(
                                title: context.tr(
                                  en: 'Projects active',
                                  ar: 'المشاريع النشطة',
                                ),
                                value: '$activeProjects',
                              ),
                              _InsightLine(
                                title: context.tr(
                                  en: 'Workspace blockers',
                                  ar: 'عوائق المساحة',
                                ),
                                value: '$blockedWorkspace',
                              ),
                              _InsightLine(
                                title: context.tr(
                                  en: 'Items closing soon',
                                  ar: 'عناصر تغلق قريبًا',
                                ),
                                value: '$dueSoon',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppHintCard(
                      title: context.tr(
                        en: 'How to use this home',
                        ar: 'كيف تستخدم هذه الرئيسية',
                      ),
                      message: context.tr(
                        en: 'Read alerts here, then open My Tasks to continue your work. Use Workspaces when you need the bigger picture.',
                        ar: 'راجع التنبيهات هنا، ثم افتح مهامي لتكمل عملك. وانتقل إلى المساحات عندما تحتاج إلى الصورة الكاملة.',
                      ),
                      icon: Icons.waves_rounded,
                      accentColor: AppColors.member,
                      backgroundColor: AppColors.memberSoft,
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

class _MemberHero extends StatelessWidget {
  const _MemberHero({
    required this.workspace,
    required this.activeProjects,
    required this.assignedTaskCount,
    required this.onOpenWorkspace,
    required this.onOpenChat,
  });

  final Workspace workspace;
  final int activeProjects;
  final int assignedTaskCount;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.xxl),
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
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppStatusBadge(
                    label: context.tr(en: 'Focus field', ar: 'حقل التركيز'),
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                  AppStatusBadge(
                    label: context.tr(
                      en: '$assignedTaskCount active items',
                      ar: '$assignedTaskCount عناصر نشطة',
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                workspace.name,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(
                  en: 'Your home is now analytics-first. See the shape of work instantly, then step into detail only when you need to act.',
                  ar: 'رئيسيتك أصبحت معتمدة على التحليلات أولًا. شاهد شكل العمل فورًا، ثم ادخل في التفاصيل فقط عندما تحتاج إلى التنفيذ.',
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 720;
                  final energyCard = AppSurfaceCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    borderColor: Colors.white.withValues(alpha: 0.18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            en: 'Workspace energy',
                            ar: 'طاقة المساحة',
                          ),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '$activeProjects',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.tr(
                            en: 'Active projects now',
                            ar: 'مشاريع نشطة الآن',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                      ],
                    ),
                  );
                  final actions = Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.inkOnLight,
                          ),
                          onPressed: onOpenWorkspace,
                          icon: const Icon(Icons.arrow_outward_rounded),
                          label: Text(
                            context.tr(en: 'Open workspace', ar: 'فتح المساحة'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          onPressed: onOpenChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: Text(
                            context.tr(en: 'Open chat', ar: 'فتح الدردشة'),
                          ),
                        ),
                      ),
                    ],
                  );
                  if (stacked) {
                    return Column(
                      children: [
                        energyCard,
                        const SizedBox(height: AppSpacing.md),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: energyCard),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(width: 220, child: actions),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalPanel extends StatelessWidget {
  const _SignalPanel({
    required this.title,
    required this.subtitle,
    required this.bars,
  });

  final String title;
  final String subtitle;
  final List<_SignalBarData> bars;

  @override
  Widget build(BuildContext context) {
    final total = bars.fold<int>(0, (sum, item) => sum + item.count);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          for (final bar in bars) ...[
            _SignalBar(total: total, data: bar),
            if (bar != bars.last) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  const _SignalBar({required this.total, required this.data});

  final int total;
  final _SignalBarData data;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (data.count / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                data.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              '${data.count}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadii.pill,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            color: data.color,
            backgroundColor: AppColors.surfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _SignalBarData {
  const _SignalBarData({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveWrapGrid(
      minItemWidth: 250,
      maxColumns: 4,
      children: children,
    );
  }
}
