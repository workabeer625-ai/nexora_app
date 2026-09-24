import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_metric_card.dart';
import '../../../../shared/widgets/app_page_top_chrome.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../domain/entities/task_item.dart';
import '../task_ui.dart';
import '../widgets/task_editor_dialog.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.userId,
    required this.workspaceId,
    required this.projectId,
    required this.taskId,
  });

  final String userId;
  final String workspaceId;
  final String projectId;
  final String taskId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<TaskItem?>(
      stream: services.taskRepository.watchTask(
        widget.workspaceId,
        widget.projectId,
        widget.taskId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppLoadingState(
              message: context.tr(
                en: 'Loading task...',
                ar: 'يتم تحميل المهمة...',
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(message: context.trError(snapshot.error)),
          );
        }

        final task = snapshot.data;
        if (task == null) {
          return Scaffold(
            body: AppErrorState(
              message: context.tr(
                en: 'Task not found.',
                ar: 'لم يتم العثور على المهمة.',
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
            final canEdit = membership != null;

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
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.xxxl,
                        ),
                        children: [
                          AppPageTopChrome(
                            title: task.title,
                            eyebrow: context.tr(
                              en: 'Task command layer',
                              ar: 'مركز قيادة المهمة',
                            ),
                            accentGradient: canManage
                                ? AppColors.adminHeroGradient
                                : AppColors.memberHeroGradient,
                            action: canEdit
                                ? AppPageTopAction(
                                    tooltip: context.tr(
                                      en: 'Edit task',
                                      ar: 'تعديل المهمة',
                                    ),
                                    icon: Icons.edit_outlined,
                                    gradient: canManage
                                        ? AppColors.adminHeroGradient
                                        : AppColors.memberHeroGradient,
                                    onPressed: () =>
                                        _showEditTaskDialog(context, task),
                                  )
                                : null,
                            badges: buildTopChromeBadges(
                              context: context,
                              labels: [
                                task.status.localizedLabel(context),
                                task.priority.localizedLabel(context),
                                if (membership != null)
                                  membership.role.localizedLabel(context),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _TaskHero(
                            task: task,
                            membership: membership,
                            canManage: canManage,
                            onEdit: canEdit
                                ? () => _showEditTaskDialog(context, task)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppHintCard(
                            title: _guidanceTitle(task, canManage),
                            message: _guidanceMessage(task, canManage),
                            accentColor: _guidanceAccent(task, canManage),
                            backgroundColor: _guidanceBackground(
                              task,
                              canManage,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _MetricGrid(
                            children: [
                              AppMetricCard(
                                label: context.tr(en: 'Progress', ar: 'التقدم'),
                                value: '${task.progress}%',
                                caption: context.tr(
                                  en: 'Current completion signal',
                                  ar: 'مؤشر الإنجاز الحالي',
                                ),
                                icon: Icons.pie_chart_outline_rounded,
                                tintColor: taskStatusTint(task.status),
                                iconColor: taskStatusForeground(task.status),
                              ),
                              AppMetricCard(
                                label: context.tr(
                                  en: 'Due date',
                                  ar: 'موعد الاستحقاق',
                                ),
                                value: AppDateFormatter.shortDateLocalized(context, task.dueDate),
                                caption: isTaskOverdue(task)
                                    ? context.tr(
                                        en: 'This task is overdue',
                                        ar: 'هذه المهمة متأخرة عن موعدها',
                                      )
                                    : isTaskDueSoon(task)
                                    ? context.tr(
                                        en: 'This task is due soon',
                                        ar: 'هذه المهمة تقترب من موعد الاستحقاق',
                                      )
                                    : context.tr(
                                        en: 'Timing looks stable',
                                        ar: 'الجدول الزمني مستقر',
                                      ),
                                icon: Icons.event_available_outlined,
                                tintColor: isTaskOverdue(task)
                                    ? AppColors.errorSoft
                                    : isTaskDueSoon(task)
                                    ? AppColors.warningSoft
                                    : AppColors.surfaceMuted,
                                iconColor: isTaskOverdue(task)
                                    ? AppColors.error
                                    : isTaskDueSoon(task)
                                    ? AppColors.warning
                                    : AppColors.ink,
                              ),
                              AppMetricCard(
                                label: context.tr(
                                  en: 'Assignee',
                                  ar: 'المكلَّف',
                                ),
                                value: compactUserLabel(
                                  task.assignedTo,
                                  fallback: context.tr(
                                    en: 'Unassigned',
                                    ar: 'غير مسندة',
                                  ),
                                ),
                                caption: context.tr(
                                  en: 'Ownership signal for the team',
                                  ar: 'مؤشر المسؤولية للفريق',
                                ),
                                icon: Icons.person_outline_rounded,
                                tintColor: AppColors.infoSoft,
                                iconColor: AppColors.info,
                              ),
                              AppMetricCard(
                                label: context.tr(
                                  en: 'Review state',
                                  ar: 'حالة المراجعة',
                                ),
                                value: task.reviewStatus == ReviewStatus.none
                                    ? context.tr(
                                        en: 'No review',
                                        ar: 'لا توجد مراجعة',
                                      )
                                    : task.reviewStatus.localizedLabel(context),
                                caption: context.tr(
                                  en: 'Approval or review requirement',
                                  ar: 'متطلبات المراجعة أو الاعتماد',
                                ),
                                icon: Icons.fact_check_outlined,
                                tintColor: reviewStatusTint(task.reviewStatus),
                                iconColor: reviewStatusForeground(
                                  task.reviewStatus,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _DetailGrid(
                            children: [
                              AppSurfaceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr(
                                        en: 'Task brief',
                                        ar: 'ملخص المهمة',
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      task.description.isEmpty
                                          ? context.tr(
                                              en: 'No written brief yet. Update the task so contributors understand the expected outcome without guessing.',
                                              ar: 'لا يوجد ملخص مكتوب بعد. حدّث المهمة حتى يفهم المساهمون النتيجة المتوقعة دون تخمين.',
                                            )
                                          : task.description,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              AppSurfaceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr(
                                        en: 'Execution details',
                                        ar: 'تفاصيل التنفيذ',
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _InfoRow(
                                      label: context.tr(
                                        en: 'Created by',
                                        ar: 'أُنشئت بواسطة',
                                      ),
                                      value: compactUserLabel(
                                        task.createdBy,
                                        fallback: context.tr(
                                          en: 'Unknown',
                                          ar: 'غير معروف',
                                        ),
                                      ),
                                    ),
                                    _InfoRow(
                                      label: context.tr(
                                        en: 'Start date',
                                        ar: 'تاريخ البدء',
                                      ),
                                      value: AppDateFormatter.shortDateLocalized(context, 
                                        task.startDate,
                                      ),
                                    ),
                                    _InfoRow(
                                      label: context.tr(
                                        en: 'Updated',
                                        ar: 'آخر تحديث',
                                      ),
                                      value: AppDateFormatter.dateTimeLocalized(context, 
                                        task.updatedAt,
                                      ),
                                    ),
                                    _InfoRow(
                                      label: context.tr(
                                        en: 'Completion date',
                                        ar: 'تاريخ الإنجاز',
                                      ),
                                      value: AppDateFormatter.dateTimeLocalized(context, 
                                        task.completedAt,
                                      ),
                                    ),
                                    if (task.isBlocked)
                                      _InfoRow(
                                        label: context.tr(
                                          en: 'Blocked reason',
                                          ar: 'سبب التوقف',
                                        ),
                                        value:
                                            task.blockedReason ??
                                            context.tr(
                                              en: 'Not provided',
                                              ar: 'غير مذكور',
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppSectionHeader(
                            title: context.tr(
                              en: 'Delivery conversation',
                              ar: 'محادثة التنفيذ',
                            ),
                            subtitle: context.tr(
                              en: 'Keep blockers, clarifications, and @mentions attached to the task so the team never loses context.',
                              ar: 'أبقِ العوائق والتوضيحات وذكر الزملاء مرتبطة بالمهمة حتى لا يفقد الفريق السياق.',
                            ),
                          ),
                          AppHintCard(
                            title: context.tr(
                              en: 'Use this thread deliberately',
                              ar: 'استخدم هذا النقاش بوعي',
                            ),
                            message: context.tr(
                              en: 'Discuss the work here, mention the right teammate, and keep the final decision visible inside the task instead of scattering it elsewhere.',
                              ar: 'ناقش العمل هنا، اذكر العضو المناسب، واجعل القرار النهائي ظاهرًا داخل المهمة بدلًا من تشتيته في مكان آخر.',
                            ),
                            accentColor: AppColors.info,
                            backgroundColor: AppColors.infoSoft,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          StreamBuilder<Workspace?>(
                            stream: services.workspaceRepository.watchWorkspace(
                              widget.workspaceId,
                            ),
                            builder: (context, workspaceSnapshot) {
                              final isWorkspaceArchived =
                                  workspaceSnapshot.data?.isArchived ?? false;

                              return TaskChatPanel(
                                currentUserId: widget.userId,
                                workspaceId: widget.workspaceId,
                                projectId: widget.projectId,
                                task: task,
                                canAccess: membership != null,
                                canModerate: canManage,
                                isReadOnly: isWorkspaceArchived,
                              );
                            },
                          ),
                        ],
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

  Future<void> _showEditTaskDialog(BuildContext context, TaskItem task) async {
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showTaskEditorDialog(
        context: context,
        workspaceId: widget.workspaceId,
        title: context.tr(en: 'Edit task', ar: 'تعديل المهمة'),
        actionLabel: context.tr(en: 'Save changes', ar: 'حفظ التغييرات'),
        helperText: context.tr(
          en: 'Keep the task sharply aligned with reality: update status, progress, ownership, and blockers so the next person knows exactly what changed.',
          ar: 'أبقِ المهمة متطابقة مع الواقع: حدّث الحالة والتقدم والمسؤولية والعوائق ليعرف الشخص التالي ما الذي تغيّر بالضبط.',
        ),
        initialTask: task,
        onSubmit: (values) async {
          await services.taskManagementService.updateTask(
            actorId: widget.userId,
            currentTask: task,
            title: values.title,
            description: values.description,
            status: values.status,
            priority: values.priority,
            assignedTo: values.assignedTo,
            startDate: values.startDate,
            dueDate: values.dueDate,
            progress: values.progress,
            blockedReason: values.blockedReason ?? '',
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

  String _guidanceTitle(TaskItem task, bool canManage) {
    if (task.status == TaskStatus.blocked) {
      return context.tr(
        en: 'This task needs an unblock decision',
        ar: 'هذه المهمة تحتاج إلى قرار لإزالة العائق',
      );
    }
    if (task.status == TaskStatus.inReview) {
      return context.tr(
        en: 'Review is the current bottleneck',
        ar: 'المراجعة هي عنق الزجاجة حاليًا',
      );
    }
    if (task.status == TaskStatus.done) {
      return context.tr(en: 'Delivery complete', ar: 'تم التسليم');
    }
    return canManage
        ? context.tr(en: 'Admin oversight', ar: 'إشراف الإدارة')
        : context.tr(en: 'Execution focus', ar: 'تركيز التنفيذ');
  }

  String _guidanceMessage(TaskItem task, bool canManage) {
    if (task.status == TaskStatus.blocked) {
      return context.tr(
        en: 'Surface the blocker clearly, assign the next decision, and use the comment thread for any unblock updates so the team does not lose context.',
        ar: 'أظهر سبب التوقف بوضوح، وحدد القرار التالي، واستخدم النقاش لأي تحديثات تخص إزالة العوائق حتى لا يفقد الفريق السياق.',
      );
    }
    if (task.status == TaskStatus.inReview) {
      return context.tr(
        en: 'Capture review feedback in comments and move the status forward quickly once the decision is clear.',
        ar: 'دوّن ملاحظات المراجعة في النقاش، وحرّك الحالة بسرعة فور اتضاح القرار.',
      );
    }
    if (task.status == TaskStatus.done) {
      return context.tr(
        en: 'Keep comments for post-delivery notes, handoff details, or anything future contributors should still be able to learn from.',
        ar: 'استخدم النقاش لملاحظات ما بعد التسليم أو تفاصيل التسليم أو أي معرفة ينبغي أن تبقى متاحة للمساهمين لاحقًا.',
      );
    }
    return canManage
        ? context.tr(
            en: 'This view is tuned for oversight: watch due dates, ownership, review state, and comments without hunting through multiple screens.',
            ar: 'هذا العرض مهيأ للإشراف: راقب المواعيد والمسؤوليات وحالة المراجعة والنقاش دون التنقل بين شاشات متعددة.',
          )
        : context.tr(
            en: 'This view is tuned for action: understand the brief, update progress honestly, and leave the next person with enough context to keep momentum.',
            ar: 'هذا العرض مهيأ للتنفيذ: افهم الملخص، وحدّث التقدم بوضوح، واترك لمن يأتي بعدك سياقًا كافيًا للحفاظ على الزخم.',
          );
  }

  Color _guidanceAccent(TaskItem task, bool canManage) {
    if (task.status == TaskStatus.blocked) {
      return AppColors.error;
    }
    if (task.status == TaskStatus.inReview) {
      return AppColors.warning;
    }
    if (task.status == TaskStatus.done) {
      return AppColors.success;
    }
    return canManage ? AppColors.admin : AppColors.member;
  }

  Color _guidanceBackground(TaskItem task, bool canManage) {
    if (task.status == TaskStatus.blocked) {
      return AppColors.errorSoft;
    }
    if (task.status == TaskStatus.inReview) {
      return AppColors.warningSoft;
    }
    if (task.status == TaskStatus.done) {
      return AppColors.successSoft;
    }
    return canManage ? AppColors.adminSoft : AppColors.memberSoft;
  }
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({
    required this.task,
    required this.membership,
    required this.canManage,
    required this.onEdit,
  });

  final TaskItem task;
  final WorkspaceMember? membership;
  final bool canManage;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final heroColors = switch (task.status) {
      TaskStatus.blocked => const <Color>[Color(0xFF7A1C1C), Color(0xFFB83232)],
      TaskStatus.inReview => const <Color>[
        Color(0xFF7A4A08),
        Color(0xFFD97706),
      ],
      TaskStatus.done => const <Color>[Color(0xFF0B5C43), Color(0xFF0C8A5B)],
      _ =>
        canManage
            ? const <Color>[Color(0xFF102E58), Color(0xFF1654B5)]
            : const <Color>[Color(0xFF0E7A66), Color(0xFF103A64)],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: heroColors,
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
                  label: task.status.localizedLabel(context),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  leading: taskStatusIcon(task.status),
                ),
                AppStatusBadge(
                  label: task.priority.localizedLabel(context),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  leading: taskPriorityIcon(task.priority),
                ),
                AppStatusBadge(
                  label: task.reviewStatus == ReviewStatus.none
                      ? context.tr(en: 'No review', ar: 'لا توجد مراجعة')
                      : context.tr(
                          en: 'Review ${task.reviewStatus.localizedLabel(context)}',
                          ar: 'المراجعة ${task.reviewStatus.localizedLabel(context)}',
                        ),
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
              task.title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              task.description.isEmpty
                  ? context.tr(
                      en: 'A short written brief has not been added yet. Use the edit action to remove ambiguity for contributors and reviewers.',
                      ar: 'لم يُضف ملخص قصير بعد. استخدم التعديل لإزالة الغموض أمام المساهمين والمراجعين.',
                    )
                  : task.description,
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
                  label: context.tr(
                    en: 'Progress ${task.progress}%',
                    ar: 'التقدم ${task.progress}%',
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                AppStatusBadge(
                  label: context.tr(
                    en: 'Assignee ${compactUserLabel(task.assignedTo, fallback: 'Unassigned')}',
                    ar: 'المكلَّف ${compactUserLabel(task.assignedTo, fallback: 'غير مسندة')}',
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                AppStatusBadge(
                  label: context.tr(
                    en: 'Due ${AppDateFormatter.shortDateLocalized(context, task.dueDate)}',
                    ar: 'الاستحقاق ${AppDateFormatter.shortDateLocalized(context, task.dueDate)}',
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            if (onEdit != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.inkOnLight,
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.tr(en: 'Edit task', ar: 'تعديل المهمة')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
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
                (child) => SizedBox(
                  width: itemWidth.clamp(0, width).toDouble(),
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: child,
                  ),
                )
                .toList(growable: false),
          );
        }

        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}
