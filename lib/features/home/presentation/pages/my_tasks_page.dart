import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/task_overview_card.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../workspaces/domain/entities/workspace.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({
    super.key,
    required this.userId,
    required this.selectedWorkspace,
  });

  final String userId;
  final Workspace? selectedWorkspace;

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  _TaskFilter _filter = _TaskFilter.active;

  @override
  Widget build(BuildContext context) {
    final workspace = widget.selectedWorkspace;
    if (workspace == null) {
      return AppEmptyState(
        title: context.tr(
          en: 'Choose a workspace first',
          ar: 'اختر مساحة عمل أولًا',
        ),
        message: context.tr(
          en:
              'My Tasks becomes useful once you select a workspace. Nexora keeps the task queue scoped so it stays clean and relevant.',
          ar:
              'تصبح صفحة مهامي مفيدة بعد اختيار مساحة عمل. يحافظ Nexora على صف المهام ضمن نطاق واضح ليبقى نظيفًا ومرتبطًا بك.',
        ),
        icon: Icons.filter_alt_off_rounded,
      );
    }

    final services = AppScope.of(context);

    return StreamBuilder<List<Project>>(
      stream: services.projectRepository.watchProjects(workspace.id),
      builder: (context, projectsSnapshot) {
        if (projectsSnapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading your tasks...',
              ar: 'يتم تحميل مهامك...',
            ),
          );
        }

        final projectMap = <String, Project>{
          for (final project in projectsSnapshot.data ?? const <Project>[])
            project.id: project,
        };

        return StreamBuilder<List<TaskItem>>(
          stream: services.taskRepository.watchAssignedWorkspaceTasks(
            workspace.id,
            widget.userId,
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
            final visibleTasks = tasks.where((task) => _matchesFilter(task)).toList(
              growable: false,
            );

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                AppSectionHeader(
                  title: context.tr(en: 'My tasks', ar: 'مهامي'),
                  subtitle: context.tr(
                    en:
                        'Work assigned to you in ${workspace.name}, filtered for fast triage.',
                    ar:
                        'الأعمال المسندة إليك داخل ${workspace.name} مع تصفية تسهّل الفرز السريع.',
                  ),
                ),
                AppHintCard(
                  title: context.tr(
                    en: 'How to use this view',
                    ar: 'كيف تستخدم هذه الصفحة',
                  ),
                  message: context.tr(
                    en:
                        'Start with active tasks, switch to due soon before the day ends, and keep blocked items visible so nothing stalls silently.',
                    ar:
                        'ابدأ بالمهام النشطة، ثم انتقل إلى القريبة من موعدها قبل نهاية اليوم، وأبقِ المهام المتوقفة ظاهرة حتى لا يتعطل شيء بصمت.',
                  ),
                  accentColor: AppColors.warning,
                  backgroundColor: AppColors.warningSoft,
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final filter in _TaskFilter.values)
                      ChoiceChip(
                        label: Text(filter.label(context)),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (visibleTasks.isEmpty)
                  AppEmptyState(
                    title: context.tr(
                      en: 'Nothing in ${_filter.label(context).toLowerCase()}',
                      ar: 'لا توجد مهام ضمن «${_filter.label(context)}» حاليًا',
                    ),
                    message: context.tr(
                      en:
                          'This queue is intentionally focused. Switch the filter or wait for new assignments in ${workspace.name}.',
                      ar:
                          'هذا الصف مخصص للتركيز. بدّل التصفية أو انتظر الإسنادات الجديدة داخل ${workspace.name}.',
                    ),
                    icon: Icons.assignment_turned_in_outlined,
                  )
                else
                  ...visibleTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TaskOverviewCard(
                        task: task,
                        projectName: projectMap[task.projectId]?.name,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TaskDetailPage(
                                userId: widget.userId,
                                workspaceId: workspace.id,
                                projectId: task.projectId,
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
        );
      },
    );
  }

  bool _matchesFilter(TaskItem task) {
    return switch (_filter) {
      _TaskFilter.active =>
        task.status != TaskStatus.done && task.status != TaskStatus.blocked,
      _TaskFilter.dueSoon => _isDueSoon(task),
      _TaskFilter.blocked => task.status == TaskStatus.blocked,
      _TaskFilter.review => task.status == TaskStatus.inReview,
      _TaskFilter.done => task.status == TaskStatus.done,
    };
  }

  bool _isDueSoon(TaskItem task) {
    final dueDate = task.dueDate;
    if (dueDate == null || task.status == TaskStatus.done) {
      return false;
    }

    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference >= 0 && difference <= 3;
  }
}

enum _TaskFilter {
  active,
  dueSoon,
  blocked,
  review,
  done;
}

extension on _TaskFilter {
  String label(BuildContext context) {
    return switch (this) {
      _TaskFilter.active => context.tr(en: 'Active', ar: 'نشطة'),
      _TaskFilter.dueSoon => context.tr(en: 'Due soon', ar: 'قريبة الاستحقاق'),
      _TaskFilter.blocked => context.tr(en: 'Blocked', ar: 'متوقفة'),
      _TaskFilter.review => context.tr(en: 'In review', ar: 'قيد المراجعة'),
      _TaskFilter.done => context.tr(en: 'Done', ar: 'منجزة'),
    };
  }
}
