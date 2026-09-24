import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_plural.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_metric_card.dart';
import '../../../../shared/widgets/app_page_top_chrome.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../tasks/presentation/task_ui.dart';
import '../../../tasks/presentation/widgets/task_editor_dialog.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../domain/entities/project.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    super.key,
    required this.userId,
    required this.workspaceId,
    required this.projectId,
  });

  final String userId;
  final String workspaceId;
  final String projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  _ProjectTaskFilter _filter = _ProjectTaskFilter.active;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<Project?>(
      stream: services.projectRepository.watchProject(
        widget.workspaceId,
        widget.projectId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppLoadingState(
              message: context.tr(
                en: 'Loading project...',
                ar: 'يتم تحميل المشروع...',
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(message: context.trError(snapshot.error)),
          );
        }

        final project = snapshot.data;
        if (project == null) {
          return Scaffold(
            body: AppErrorState(
              message: context.tr(
                en: 'Project not found.',
                ar: 'لم يتم العثور على المشروع.',
              ),
            ),
          );
        }

        return StreamBuilder<WorkspaceMember?>(
          stream: services.workspaceRepository.watchMember(
            widget.workspaceId,
            widget.userId,
          ),
          builder: (context, membershipSnapshot) {
            final membership = membershipSnapshot.data;
            final canManage =
                membership?.role == WorkspaceRole.owner ||
                membership?.role == WorkspaceRole.admin;
            final canContribute = membership != null;

            return Scaffold(
              body: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.pageGradient,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: StreamBuilder<List<TaskItem>>(
                        stream: services.taskRepository.watchTasks(
                          widget.workspaceId,
                          widget.projectId,
                        ),
                        builder: (context, taskSnapshot) {
                          if (taskSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return AppLoadingState(
                              message: context.tr(
                                en: 'Loading project tasks...',
                                ar: 'يتم تحميل مهام المشروع...',
                              ),
                            );
                          }

                          if (taskSnapshot.hasError) {
                            return AppErrorState(
                              message: context.trError(taskSnapshot.error),
                            );
                          }

                          final tasks = taskSnapshot.data ?? const <TaskItem>[];
                          final filteredTasks = _applyFilter(tasks);
                          final completedCount = tasks
                              .where((task) => task.status == TaskStatus.done)
                              .length;
                          final blockedCount = tasks
                              .where(
                                (task) => task.status == TaskStatus.blocked,
                              )
                              .length;
                          final assignedToMeCount = tasks
                              .where((task) => task.assignedTo == widget.userId)
                              .length;
                          final dueSoonCount = tasks
                              .where(isTaskDueSoon)
                              .length;

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.xxxl,
                            ),
                            children: [
                              AppPageTopChrome(
                                title: project.name,
                                eyebrow: context.tr(
                                  en: 'Project command layer',
                                  ar: 'مركز قيادة المشروع',
                                ),
                                accentGradient: canManage
                                    ? AppColors.adminHeroGradient
                                    : AppColors.memberHeroGradient,
                                action: canContribute
                                    ? AppPageTopAction(
                                        tooltip: context.tr(
                                          en: 'Create task',
                                          ar: 'إنشاء مهمة',
                                        ),
                                        icon: Icons.add_task_outlined,
                                        gradient: canManage
                                            ? AppColors.adminHeroGradient
                                            : AppColors.memberHeroGradient,
                                        onPressed: () =>
                                            _showCreateTaskDialog(context),
                                      )
                                    : null,
                                badges: buildTopChromeBadges(
                                  context: context,
                                  labels: [
                                    project.status.localizedLabel(context),
                                    if (membership != null)
                                      membership.role.localizedLabel(context),
                                    context.trCount(
                                      completedCount,
                                      enOne: '{n} completed',
                                      enOther: '{n} completed',
                                      arZero: 'لا مهام مكتملة',
                                      arOne: 'مهمة مكتملة واحدة',
                                      arTwo: 'مهمتان مكتملتان',
                                      arFew: '{n} مهام مكتملة',
                                      arMany: '{n} مهمة مكتملة',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _ProjectHero(
                                project: project,
                                membership: membership,
                                canManage: canManage,
                                taskCount: tasks.length,
                                onCreateTask: canContribute
                                    ? () => _showCreateTaskDialog(context)
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _MetricGrid(
                                children: [
                                  AppMetricCard(
                                    label: context.tr(
                                      en: 'Tasks',
                                      ar: 'المهام',
                                    ),
                                    value: '${tasks.length}',
                                    caption: context.tr(
                                      en: 'Everything tracked in this project',
                                      ar: 'كل ما يتتبعه الفريق في هذا المشروع',
                                    ),
                                    icon: Icons.format_list_bulleted_rounded,
                                  ),
                                  AppMetricCard(
                                    label: context.tr(
                                      en: 'Completed',
                                      ar: 'المكتملة',
                                    ),
                                    value: '$completedCount',
                                    caption: context.tr(
                                      en: 'Delivered items already closed',
                                      ar: 'عناصر أُنجزت وسُلّمت بالفعل',
                                    ),
                                    icon: Icons.check_circle_outline_rounded,
                                    tintColor: AppColors.successSoft,
                                    iconColor: AppColors.success,
                                  ),
                                  AppMetricCard(
                                    label: context.tr(
                                      en: 'Blocked',
                                      ar: 'المتوقفة',
                                    ),
                                    value: '$blockedCount',
                                    caption: context.tr(
                                      en: 'Work needing a decision or unblock',
                                      ar: 'أعمال تحتاج قرارًا أو إزالة عائق',
                                    ),
                                    icon: Icons.block_rounded,
                                    tintColor: AppColors.errorSoft,
                                    iconColor: AppColors.error,
                                  ),
                                  AppMetricCard(
                                    label: context.tr(
                                      en: 'Assigned to me',
                                      ar: 'المسندة إليّ',
                                    ),
                                    value: '$assignedToMeCount',
                                    caption: dueSoonCount == 0
                                        ? context.tr(
                                            en: 'No due-soon items right now',
                                            ar: 'لا توجد عناصر قريبة الاستحقاق الآن',
                                          )
                                        : context.trCount(
                                            dueSoonCount,
                                            enOne: '{n} due soon',
                                            enOther: '{n} due soon',
                                            arZero: 'لا عناصر قريبة الاستحقاق',
                                            arOne: 'عنصر قريب الاستحقاق',
                                            arTwo: 'عنصران قريبا الاستحقاق',
                                            arFew: '{n} عناصر قريبة الاستحقاق',
                                            arMany: '{n} عنصرًا قريب الاستحقاق',
                                          ),
                                    icon: Icons.track_changes_outlined,
                                    tintColor: AppColors.infoSoft,
                                    iconColor: AppColors.info,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AppHintCard(
                                title: canManage
                                    ? context.tr(
                                        en: 'Admin view',
                                        ar: 'عرض الإدارة',
                                      )
                                    : context.tr(
                                        en: 'Member view',
                                        ar: 'عرض العضو',
                                      ),
                                message: canManage
                                    ? context.tr(
                                        en: 'Use this page to keep execution healthy: watch blocked work, tighten priorities, and seed the next tasks without clutter.',
                                        ar: 'استخدم هذه الصفحة للحفاظ على صحة التنفيذ: راقب الأعمال المتوقفة، واضبط الأولويات، وأضف المهام التالية دون تشتيت.',
                                      )
                                    : context.tr(
                                        en: 'This page is organized around what matters now: open tasks, what is assigned to you, and where delivery might stall.',
                                        ar: 'هذه الصفحة منظمة حول ما يهم الآن: المهام المفتوحة، وما هو مسند إليك، وأين قد يتعطل التسليم.',
                                      ),
                                accentColor: canManage
                                    ? AppColors.admin
                                    : AppColors.member,
                                backgroundColor: canManage
                                    ? AppColors.adminSoft
                                    : AppColors.memberSoft,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AppSectionHeader(
                                title: context.tr(
                                  en: 'Execution board',
                                  ar: 'لوحة التنفيذ',
                                ),
                                subtitle: context.tr(
                                  en: 'Open a task to see discussion, progress, review state, and due dates in one place.',
                                  ar: 'افتح أي مهمة لرؤية النقاش والتقدم وحالة المراجعة ومواعيد الاستحقاق في مكان واحد.',
                                ),
                                trailing: canContribute
                                    ? FilledButton.icon(
                                        onPressed: () =>
                                            _showCreateTaskDialog(context),
                                        icon: const Icon(Icons.add),
                                        label: Text(
                                          context.tr(
                                            en: 'New task',
                                            ar: 'مهمة جديدة',
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _ProjectTaskFilter.values
                                      .map((filter) {
                                        final selected = _filter == filter;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: AppSpacing.sm,
                                          ),
                                          child: FilterChip(
                                            selected: selected,
                                            avatar: Icon(filter.icon, size: 18),
                                            label: Text(filter.label(context)),
                                            onSelected: (_) {
                                              setState(() => _filter = filter);
                                            },
                                          ),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              if (tasks.isEmpty)
                                AppEmptyState(
                                  title: context.tr(
                                    en: 'No tasks yet',
                                    ar: 'لا توجد مهام بعد',
                                  ),
                                  message: canContribute
                                      ? context.tr(
                                          en: 'Create the first task to turn this project from intent into execution.',
                                          ar: 'أنشئ أول مهمة لتحويل هذا المشروع من فكرة إلى تنفيذ فعلي.',
                                        )
                                      : context.tr(
                                          en: 'Tasks will appear here once the team starts breaking delivery into actionable work.',
                                          ar: 'ستظهر المهام هنا عندما يبدأ الفريق بتقسيم التنفيذ إلى مهام قابلة للتنفيذ.',
                                        ),
                                  icon: Icons.assignment_outlined,
                                  action: canContribute
                                      ? FilledButton.icon(
                                          onPressed: () =>
                                              _showCreateTaskDialog(context),
                                          icon: const Icon(Icons.add),
                                          label: Text(
                                            context.tr(
                                              en: 'Create first task',
                                              ar: 'إنشاء أول مهمة',
                                            ),
                                          ),
                                        )
                                      : null,
                                )
                              else if (filteredTasks.isEmpty)
                                AppEmptyState(
                                  title: context.tr(
                                    en: 'Nothing in this view',
                                    ar: 'لا يوجد شيء في هذا العرض',
                                  ),
                                  message: context.tr(
                                    en: 'Try a different filter or create a new task to keep the project moving.',
                                    ar: 'جرّب تصفية مختلفة أو أنشئ مهمة جديدة للحفاظ على حركة المشروع.',
                                  ),
                                  icon: Icons.filter_alt_off_outlined,
                                )
                              else
                                ...filteredTasks.map(
                                  (task) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: _ProjectTaskCard(
                                      task: task,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => TaskDetailPage(
                                              userId: widget.userId,
                                              workspaceId: widget.workspaceId,
                                              projectId: widget.projectId,
                                              taskId: task.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<TaskItem> _applyFilter(List<TaskItem> tasks) {
    final filtered = switch (_filter) {
      _ProjectTaskFilter.all => tasks,
      _ProjectTaskFilter.active =>
        tasks
            .where((task) => task.status != TaskStatus.done)
            .toList(growable: false),
      _ProjectTaskFilter.mine =>
        tasks
            .where((task) => task.assignedTo == widget.userId)
            .toList(growable: false),
      _ProjectTaskFilter.blocked =>
        tasks
            .where((task) => task.status == TaskStatus.blocked)
            .toList(growable: false),
      _ProjectTaskFilter.done =>
        tasks
            .where((task) => task.status == TaskStatus.done)
            .toList(growable: false),
    };

    filtered.sort((a, b) {
      final aDue = a.dueDate ?? DateTime(2200);
      final bDue = b.dueDate ?? DateTime(2200);
      return aDue.compareTo(bDue);
    });

    return filtered;
  }

  Future<void> _showCreateTaskDialog(BuildContext context) async {
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showTaskEditorDialog(
        context: context,
        workspaceId: widget.workspaceId,
        title: context.tr(en: 'Create task', ar: 'إنشاء مهمة'),
        actionLabel: context.tr(en: 'Create task', ar: 'إنشاء مهمة'),
        helperText: context.tr(
          en: 'Define the outcome clearly so the assignee understands what done means without reading extra chat or comments.',
          ar: 'عرّف النتيجة بوضوح حتى يفهم المكلَّف ماذا يعني الإنجاز دون الحاجة لقراءة محادثات إضافية أو تعليقات متفرقة.',
        ),
        onSubmit: (values) async {
          await services.taskManagementService.createTask(
            actorId: widget.userId,
            workspaceId: widget.workspaceId,
            projectId: widget.projectId,
            title: values.title,
            description: values.description,
            status: values.status,
            priority: values.priority,
            assignedTo: values.assignedTo,
            startDate: values.startDate,
            dueDate: values.dueDate,
            progress: values.progress,
            blockedReason: values.blockedReason,
            reviewStatus: values.reviewStatus,
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(context.trError(error))),
      );
    }
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({
    required this.project,
    required this.membership,
    required this.canManage,
    required this.taskCount,
    required this.onCreateTask,
  });

  final Project project;
  final WorkspaceMember? membership;
  final bool canManage;
  final int taskCount;
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canManage
              ? const <Color>[Color(0xFF102E58), Color(0xFF1654B5)]
              : const <Color>[Color(0xFF0E7A66), Color(0xFF103A64)],
        ),
        borderRadius: AppRadii.large,
        boxShadow: AppShadows.soft,
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
                  label: canManage
                      ? context.tr(
                          en: 'Admin project view',
                          ar: 'عرض المشروع للإدارة',
                        )
                      : context.tr(
                          en: 'Member project view',
                          ar: 'عرض المشروع للعضو',
                        ),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  leading: canManage
                      ? Icons.admin_panel_settings_outlined
                      : Icons.space_dashboard_outlined,
                ),
                AppStatusBadge(
                  label: project.status.localizedLabel(context),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                if (membership != null)
                  AppStatusBadge(
                    label: membership!.role.localizedLabel(context),
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              project.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              project.description.isEmpty
                  ? context.tr(
                      en: 'This project does not have a description yet. Add one so contributors understand the scope quickly.',
                      ar: 'لا يوجد وصف لهذا المشروع بعد. أضف وصفًا حتى يفهم المساهمون النطاق بسرعة.',
                    )
                  : project.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusBadge(
                  label: context.trCount(
                    taskCount,
                    enOne: '{n} tracked task',
                    enOther: '{n} tracked tasks',
                    arZero: 'لا مهام',
                    arOne: 'مهمة واحدة',
                    arTwo: 'مهمتان',
                    arFew: '{n} مهام',
                    arMany: '{n} مهمة',
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                AppStatusBadge(
                  label: context.tr(
                    en: 'Created ${AppDateFormatter.dateTimeLocalized(context, project.createdAt)}',
                    ar: 'أُنشئ ${AppDateFormatter.dateTimeLocalized(context, project.createdAt)}',
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                AppStatusBadge(
                  label: context.tr(
                    en: 'Owner ${compactUserLabel(project.createdBy, fallback: 'Unknown')}',
                    ar: 'المالك ${compactUserLabel(project.createdBy, fallback: 'غير معروف')}',
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            if (onCreateTask != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.inkOnLight,
                ),
                onPressed: onCreateTask,
                icon: const Icon(Icons.add_task_outlined),
                label: Text(context.tr(en: 'Create task', ar: 'إنشاء مهمة')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectTaskCard extends StatelessWidget {
  const _ProjectTaskCard({required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = isTaskOverdue(task);
    final dueSoon = isTaskDueSoon(task);

    return InkWell(
      borderRadius: AppRadii.large,
      onTap: onTap,
      child: AppSurfaceCard(
        child: Column(
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        task.description.isEmpty
                            ? context.tr(
                                en: 'No description yet.',
                                ar: 'لا يوجد وصف بعد.',
                              )
                            : task.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusBadge(
                  label: task.status.localizedLabel(context),
                  backgroundColor: taskStatusTint(task.status),
                  foregroundColor: taskStatusForeground(task.status),
                  leading: taskStatusIcon(task.status),
                ),
                AppStatusBadge(
                  label: task.priority.localizedLabel(context),
                  backgroundColor: taskPriorityTint(task.priority),
                  foregroundColor: taskPriorityForeground(task.priority),
                  leading: taskPriorityIcon(task.priority),
                ),
                AppStatusBadge(
                  label: task.reviewStatus == ReviewStatus.none
                      ? context.tr(en: 'No review', ar: 'لا توجد مراجعة')
                      : context.tr(
                          en: 'Review ${task.reviewStatus.localizedLabel(context)}',
                          ar: 'المراجعة ${task.reviewStatus.localizedLabel(context)}',
                        ),
                  backgroundColor: reviewStatusTint(task.reviewStatus),
                  foregroundColor: reviewStatusForeground(task.reviewStatus),
                ),
                if (overdue)
                  AppStatusBadge(
                    label: context.tr(en: 'Overdue', ar: 'متأخرة'),
                    backgroundColor: AppColors.errorSoft,
                    foregroundColor: AppColors.error,
                    leading: Icons.error_outline_rounded,
                  )
                else if (dueSoon)
                  AppStatusBadge(
                    label: context.tr(en: 'Due soon', ar: 'قريبة الاستحقاق'),
                    backgroundColor: AppColors.warningSoft,
                    foregroundColor: AppColors.warning,
                    leading: Icons.schedule_rounded,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: AppRadii.pill,
              child: LinearProgressIndicator(
                value: task.progress / 100,
                minHeight: 10,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  taskStatusForeground(task.status),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr(
                en: '${task.progress}% complete',
                ar: '${task.progress}% مكتمل',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _TaskMeta(
                  icon: Icons.person_outline_rounded,
                  label: context.tr(en: 'Assignee', ar: 'المكلَّف'),
                  value: compactUserLabel(
                    task.assignedTo,
                    fallback: context.tr(en: 'Unassigned', ar: 'غير مسندة'),
                  ),
                ),
                _TaskMeta(
                  icon: Icons.event_outlined,
                  label: context.tr(en: 'Due', ar: 'الاستحقاق'),
                  value: AppDateFormatter.shortDateLocalized(context, task.dueDate),
                ),
                _TaskMeta(
                  icon: Icons.update_rounded,
                  label: context.tr(en: 'Updated', ar: 'آخر تحديث'),
                  value: AppDateFormatter.dateTimeLocalized(context, task.updatedAt),
                ),
              ],
            ),
            if (task.isBlocked && task.blockedReason != null) ...[
              const SizedBox(height: AppSpacing.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: AppRadii.medium,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          task.blockedReason!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xs),
        Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1080
            ? 4
            : width >= 760
            ? 2
            : 1;
        final itemWidth = (width - (AppSpacing.md * (columns - 1))) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: children
              .map(
                (child) =>
                    SizedBox(width: itemWidth.clamp(0, width), child: child),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

enum _ProjectTaskFilter { all, active, mine, blocked, done }

extension on _ProjectTaskFilter {
  String label(BuildContext context) {
    return switch (this) {
      _ProjectTaskFilter.all => context.tr(en: 'All tasks', ar: 'كل المهام'),
      _ProjectTaskFilter.active => context.tr(en: 'Active', ar: 'النشطة'),
      _ProjectTaskFilter.mine => context.tr(
        en: 'Assigned to me',
        ar: 'المسندة إليّ',
      ),
      _ProjectTaskFilter.blocked => context.tr(en: 'Blocked', ar: 'المتوقفة'),
      _ProjectTaskFilter.done => context.tr(en: 'Done', ar: 'المنجزة'),
    };
  }

  IconData get icon {
    return switch (this) {
      _ProjectTaskFilter.all => Icons.grid_view_rounded,
      _ProjectTaskFilter.active => Icons.flash_on_outlined,
      _ProjectTaskFilter.mine => Icons.person_pin_circle_outlined,
      _ProjectTaskFilter.blocked => Icons.block_rounded,
      _ProjectTaskFilter.done => Icons.check_circle_outline_rounded,
    };
  }
}
