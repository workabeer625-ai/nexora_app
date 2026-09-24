import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_plural.dart';
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
import '../../../workspace_join/domain/entities/workspace_join_request.dart'
    show WorkspaceJoinRequest, WorkspaceJoinRequestStatus;
import '../../../workspace_join/presentation/pages/join_requests_admin_page.dart';
import '../../../workspace_join/presentation/widgets/workspace_invite_panel.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../../workspaces/presentation/pages/workspace_detail_page.dart';

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
          en: 'Pick or create a workspace to unlock the analytics layer, access controls, and delivery pulse.',
          ar: 'اختر مساحة عمل أو أنشئ واحدة لفتح طبقة التحليلات والتحكم بالوصول ونبض التنفيذ.',
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

    return StreamBuilder<List<Project>>(
      stream: services.projectRepository.watchProjects(workspace.id),
      builder: (context, projectsSnapshot) {
        if (projectsSnapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading admin analytics...',
              ar: 'يتم تحميل تحليلات الإدارة...',
            ),
          );
        }

        final projects = projectsSnapshot.data ?? const <Project>[];

        return StreamBuilder<List<TaskItem>>(
          stream: services.taskRepository.watchWorkspaceTasks(workspace.id),
          builder: (context, tasksSnapshot) {
            if (tasksSnapshot.connectionState == ConnectionState.waiting) {
              return AppLoadingState(
                message: context.tr(
                  en: 'Loading execution signals...',
                  ar: 'يتم تحميل إشارات التنفيذ...',
                ),
              );
            }

            final tasks = tasksSnapshot.data ?? const <TaskItem>[];

            return StreamBuilder<List<WorkspaceJoinRequest>>(
              stream: services.workspaceJoinService.watchJoinRequests(
                workspace.id,
              ),
              builder: (context, requestsSnapshot) {
                if (requestsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return AppLoadingState(
                    message: context.tr(
                      en: 'Loading access analytics...',
                      ar: 'يتم تحميل تحليلات الوصول...',
                    ),
                  );
                }

                final requests =
                    requestsSnapshot.data ?? const <WorkspaceJoinRequest>[];

                return StreamBuilder<List<WorkspaceMember>>(
                  stream: services.workspaceRepository.watchMembers(
                    workspace.id,
                  ),
                  builder: (context, membersSnapshot) {
                    if (membersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return AppLoadingState(
                        message: context.tr(
                          en: 'Loading team intelligence...',
                          ar: 'يتم تحميل ذكاء الفريق...',
                        ),
                      );
                    }

                    final members =
                        membersSnapshot.data ?? const <WorkspaceMember>[];

                    final pendingRequests = requests
                        .where(
                          (request) =>
                              request.status ==
                              WorkspaceJoinRequestStatus.pending,
                        )
                        .length;
                    final approvedRequests = requests
                        .where(
                          (request) =>
                              request.status ==
                              WorkspaceJoinRequestStatus.approved,
                        )
                        .length;
                    final rejectedRequests = requests
                        .where(
                          (request) =>
                              request.status ==
                              WorkspaceJoinRequestStatus.rejected,
                        )
                        .length;

                    final activeProjects = projects
                        .where(
                          (project) => project.status == ProjectStatus.active,
                        )
                        .length;
                    final plannedProjects = projects
                        .where(
                          (project) => project.status == ProjectStatus.planned,
                        )
                        .length;
                    final onHoldProjects = projects
                        .where(
                          (project) => project.status == ProjectStatus.onHold,
                        )
                        .length;
                    final completedProjects = projects
                        .where(
                          (project) =>
                              project.status == ProjectStatus.completed,
                        )
                        .length;

                    final blockedTasks = tasks
                        .where((task) => task.status == TaskStatus.blocked)
                        .length;
                    final reviewTasks = tasks
                        .where((task) => task.status == TaskStatus.inReview)
                        .length;
                    final doneTasks = tasks
                        .where((task) => task.status == TaskStatus.done)
                        .length;
                    final liveTasks = tasks.length - doneTasks;
                    final deliveryScore = tasks.isEmpty
                        ? 0.0
                        : (doneTasks / tasks.length).clamp(0.0, 1.0);

                    return ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                      children: [
                        if (topHeader != null) ...[
                          topHeader!,
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        _AnalyticsHero(
                          workspace: workspace,
                          pendingRequests: pendingRequests,
                          deliveryScore: deliveryScore,
                          onOpenWorkspace: openWorkspaceDetail,
                          onOpenChat: openWorkspaceChat,
                          onReviewRequests: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => JoinRequestsAdminPage(
                                  workspaceId: workspace.id,
                                  reviewerUserId: userId,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppSectionHeader(
                          title: context.tr(
                            en: 'Control actions',
                            ar: 'إجراءات التحكم',
                          ),
                          subtitle: context.tr(
                            en: 'Keep access, delivery, and workspace structure under one deliberate admin flow.',
                            ar: 'حافظ على الوصول والتنفيذ وبنية المساحة ضمن مسار إداري واضح ومقصود.',
                          ),
                        ),
                        AppResponsiveWrapGrid(
                          minItemWidth: 300,
                          maxColumns: 3,
                          children: [
                            AppActionTile(
                              icon: Icons.fact_check_outlined,
                              title: context.tr(
                                en: 'Review join requests',
                                ar: 'مراجعة طلبات الانضمام',
                              ),
                              description: context.tr(
                                en: 'Approve the right people, reject unclear requests, and keep access intentional.',
                                ar: 'وافق على الأشخاص المناسبين، ارفض الطلبات غير الواضحة، وحافظ على الوصول مضبوطًا.',
                              ),
                              ctaLabel: context.tr(
                                en: 'Open requests',
                                ar: 'فتح الطلبات',
                              ),
                              onPressed: onOpenRequests,
                              badgeLabel: context.trCount(
                                pendingRequests,
                                enOne: '{n} pending',
                                enOther: '{n} pending',
                                arZero: 'لا طلبات قيد الانتظار',
                                arOne: 'طلب واحد قيد الانتظار',
                                arTwo: 'طلبان قيد الانتظار',
                                arFew: '{n} طلبات قيد الانتظار',
                                arMany: '{n} طلبًا قيد الانتظار',
                              ),
                              badgeColor: pendingRequests > 0
                                  ? AppColors.warningSoft
                                  : AppColors.surfaceMuted,
                              iconBackground: AppColors.warningSoft,
                              iconColor: AppColors.warning,
                            ),
                            AppActionTile(
                              icon: Icons.workspaces_outline,
                              title: context.tr(
                                en: 'Open workspace structure',
                                ar: 'فتح بنية المساحة',
                              ),
                              description: context.tr(
                                en: 'Manage current workspace context, member roles, team chat, and the active projects view.',
                                ar: 'أدر سياق المساحة الحالية وأدوار الأعضاء ودردشة الفريق وعرض المشاريع النشطة.',
                              ),
                              ctaLabel: context.tr(
                                en: 'Open workspace',
                                ar: 'فتح المساحة',
                              ),
                              onPressed: openWorkspaceDetail,
                              badgeLabel: context.tr(
                                en: 'Projects + Team + Chat',
                                ar: 'المشاريع + الفريق + الدردشة',
                              ),
                              badgeColor: AppColors.infoSoft,
                              iconBackground: AppColors.infoSoft,
                              iconColor: AppColors.info,
                            ),
                            AppActionTile(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: context.tr(
                                en: 'Open team chat',
                                ar: 'فتح دردشة الفريق',
                              ),
                              description: context.tr(
                                en: 'Go straight to the workspace conversation for approvals, handoffs, and quick admin decisions.',
                                ar: 'ادخل مباشرة إلى دردشة الفريق للموافقات وتسليم المهام والقرارات الإدارية السريعة.',
                              ),
                              ctaLabel: context.tr(
                                en: 'Open chat',
                                ar: 'فتح الدردشة',
                              ),
                              onPressed: openWorkspaceChat,
                              badgeLabel: context.tr(
                                en: 'Live thread',
                                ar: 'محادثة مباشرة',
                              ),
                              badgeColor: AppColors.adminSoft,
                              iconBackground: AppColors.adminSoft,
                              iconColor: AppColors.admin,
                            ),
                            AppActionTile(
                              icon: Icons.key_rounded,
                              title: context.tr(
                                en: 'Refresh join access',
                                ar: 'تحديث وصول الانضمام',
                              ),
                              description: context.tr(
                                en: 'Go to workspace controls to regenerate join codes and manage controlled onboarding.',
                                ar: 'انتقل إلى تحكم المساحة لإعادة توليد أكواد الانضمام وإدارة انضمام الأعضاء الجدد.',
                              ),
                              ctaLabel: context.tr(
                                en: 'Open controls',
                                ar: 'فتح التحكم',
                              ),
                              onPressed: onOpenWorkspaces,
                              badgeLabel: context.tr(
                                en: 'Admin controls',
                                ar: 'أدوات الإدارة',
                              ),
                              badgeColor: AppColors.adminSoft,
                              iconBackground: AppColors.adminSoft,
                              iconColor: AppColors.admin,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _MetricGrid(
                          children: [
                            AppMetricCard(
                              label: context.tr(
                                en: 'Pending approvals',
                                ar: 'موافقات معلّقة',
                              ),
                              value: '$pendingRequests',
                              caption: context.tr(
                                en: 'People waiting to enter the workspace',
                                ar: 'أشخاص ينتظرون دخول المساحة',
                              ),
                              icon: Icons.fact_check_outlined,
                              tintColor: AppColors.warningSoft,
                              iconColor: AppColors.warning,
                              glow: pendingRequests > 0,
                            ),
                            AppMetricCard(
                              label: context.tr(
                                en: 'Team size',
                                ar: 'حجم الفريق',
                              ),
                              value: '${members.length}',
                              caption: context.tr(
                                en: 'Active people in this workspace',
                                ar: 'عدد الأشخاص النشطين في مساحة العمل',
                              ),
                              icon: Icons.groups_2_outlined,
                              tintColor: AppColors.adminSoft,
                              iconColor: AppColors.admin,
                            ),
                            AppMetricCard(
                              label: context.tr(
                                en: 'Active projects',
                                ar: 'المشاريع النشطة',
                              ),
                              value: '$activeProjects',
                              caption: context.tr(
                                en: 'Projects currently moving through delivery',
                                ar: 'مشاريع تتحرك حاليًا في مرحلة التنفيذ',
                              ),
                              icon: Icons.layers_outlined,
                              tintColor: AppColors.infoSoft,
                              iconColor: AppColors.info,
                            ),
                            AppMetricCard(
                              label: context.tr(
                                en: 'Tasks at risk',
                                ar: 'المهام المعرضة للخطر',
                              ),
                              value: '${blockedTasks + reviewTasks}',
                              caption: context.tr(
                                en: 'Blocked or stuck in review right now',
                                ar: 'متوقفة أو عالقة في المراجعة الآن',
                              ),
                              icon: Icons.warning_amber_rounded,
                              tintColor: AppColors.errorSoft,
                              iconColor: AppColors.error,
                              glow: blockedTasks + reviewTasks > 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppSectionHeader(
                          title: context.tr(
                            en: 'Operational intelligence',
                            ar: 'الذكاء التشغيلي',
                          ),
                          subtitle: context.tr(
                            en: 'A compact read on delivery, access, and growth without digging through long lists.',
                            ar: 'قراءة مركزة للتنفيذ والوصول والنمو دون الغوص في القوائم التفصيلية.',
                          ),
                        ),
                        _MetricGrid(
                          children: [
                            _SignalPanel(
                              title: context.tr(
                                en: 'Project mix',
                                ar: 'مزيج المشاريع',
                              ),
                              subtitle: context.tr(
                                en: 'How the workspace projects are distributed now.',
                                ar: 'كيف تتوزع مشاريع المساحة الآن.',
                              ),
                              bars: [
                                _SignalBarData(
                                  label: context.tr(en: 'Active', ar: 'نشطة'),
                                  count: activeProjects,
                                  color: AppColors.info,
                                ),
                                _SignalBarData(
                                  label: context.tr(en: 'Planned', ar: 'مخططة'),
                                  count: plannedProjects,
                                  color: AppColors.primary,
                                ),
                                _SignalBarData(
                                  label: context.tr(en: 'On hold', ar: 'معلّقة'),
                                  count: onHoldProjects,
                                  color: AppColors.warning,
                                ),
                                _SignalBarData(
                                  label: context.tr(
                                    en: 'Completed',
                                    ar: 'مكتملة',
                                  ),
                                  count: completedProjects,
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                            _SignalPanel(
                              title: context.tr(
                                en: 'Access flow',
                                ar: 'حركة الوصول',
                              ),
                              subtitle: context.tr(
                                en: 'Join traffic, decisions, and queue pressure.',
                                ar: 'حركة طلبات الانضمام والقرارات وضغط صف الانتظار.',
                              ),
                              bars: [
                                _SignalBarData(
                                  label: context.tr(
                                    en: 'Pending',
                                    ar: 'قيد الانتظار',
                                  ),
                                  count: pendingRequests,
                                  color: AppColors.warning,
                                ),
                                _SignalBarData(
                                  label: context.tr(
                                    en: 'Approved',
                                    ar: 'مقبولة',
                                  ),
                                  count: approvedRequests,
                                  color: AppColors.success,
                                ),
                                _SignalBarData(
                                  label: context.tr(
                                    en: 'Rejected',
                                    ar: 'مرفوضة',
                                  ),
                                  count: rejectedRequests,
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                            _SignalPanel(
                              title: context.tr(
                                en: 'Execution health',
                                ar: 'صحة التنفيذ',
                              ),
                              subtitle: context.tr(
                                en: 'Live work against delivered work and current friction.',
                                ar: 'مقارنة العمل الحي بالمنجز والعوائق الحالية.',
                              ),
                              bars: [
                                _SignalBarData(
                                  label: context.tr(en: 'Live', ar: 'جارية'),
                                  count: liveTasks,
                                  color: AppColors.info,
                                ),
                                _SignalBarData(
                                  label: context.tr(en: 'Done', ar: 'منجزة'),
                                  count: doneTasks,
                                  color: AppColors.success,
                                ),
                                _SignalBarData(
                                  label: context.tr(
                                    en: 'Blocked',
                                    ar: 'متوقفة',
                                  ),
                                  count: blockedTasks,
                                  color: AppColors.error,
                                ),
                                _SignalBarData(
                                  label: context.tr(
                                    en: 'In review',
                                    ar: 'قيد المراجعة',
                                  ),
                                  count: reviewTasks,
                                  color: AppColors.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppHintCard(
                          title: context.tr(
                            en: 'Admin guidance',
                            ar: 'إرشادات الإدارة',
                          ),
                          message: context.tr(
                            en: 'Read the queue first, clear blocked work second, then keep join codes fresh when onboarding a new wave of members.',
                            ar: 'ابدأ بقراءة صف الطلبات، ثم أزل عوائق التنفيذ، ثم جدّد أكواد الانضمام عند إدخال دفعة جديدة من الأعضاء.',
                          ),
                          icon: Icons.radar_outlined,
                          accentColor: AppColors.admin,
                          backgroundColor: AppColors.adminSoft,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppSectionHeader(
                          title: context.tr(
                            en: 'Access controls',
                            ar: 'التحكم بالوصول',
                          ),
                          subtitle: context.tr(
                            en: 'Generate controlled entry without exposing the workspace to direct joins.',
                            ar: 'أنشئ دخولًا مضبوطًا دون كشف المساحة لانضمام مباشر وغير مراقب.',
                          ),
                        ),
                        WorkspaceInvitePanel(
                          workspaceId: workspace.id,
                          actorUserId: userId,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({
    required this.workspace,
    required this.pendingRequests,
    required this.deliveryScore,
    required this.onOpenWorkspace,
    required this.onOpenChat,
    required this.onReviewRequests,
  });

  final Workspace workspace;
  final int pendingRequests;
  final double deliveryScore;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onOpenChat;
  final VoidCallback onReviewRequests;

  @override
  Widget build(BuildContext context) {
    final scoreText = '${(deliveryScore * 100).round()}%';
    return AppSurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.xxl),
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
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppStatusBadge(
                    label: context.tr(
                      en: 'Analytics core',
                      ar: 'نواة التحليلات',
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                  AppStatusBadge(
                    label: context.trCount(
                      pendingRequests,
                      enOne: '{n} request waiting',
                      enOther: '{n} requests waiting',
                      arZero: 'لا طلبات بانتظار المراجعة',
                      arOne: 'طلب واحد بانتظار المراجعة',
                      arTwo: 'طلبان بانتظار المراجعة',
                      arFew: '{n} طلبات بانتظار المراجعة',
                      arMany: '{n} طلبًا بانتظار المراجعة',
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
                  en: 'Track access, activity, and team health from one place.',
                  ar: 'تابع الوصول والنشاط وحالة الفريق من مكان واحد.',
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 640;
                  final scoreCard = AppSurfaceCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    borderColor: Colors.white.withValues(alpha: 0.18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(en: 'Delivery score', ar: 'درجة التسليم'),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          scoreText,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: AppRadii.pill,
                          child: LinearProgressIndicator(
                            value: deliveryScore,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            color: Colors.white,
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
                        scoreCard,
                        const SizedBox(height: AppSpacing.md),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: scoreCard),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: actions),
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
