import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../domain/entities/task_item.dart';

class TaskEditorValues {
  const TaskEditorValues({
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.startDate,
    required this.dueDate,
    required this.progress,
    required this.priority,
    required this.status,
    required this.reviewStatus,
    required this.blockedReason,
  });

  final String title;
  final String description;
  final String? assignedTo;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int progress;
  final TaskPriority priority;
  final TaskStatus status;
  final ReviewStatus reviewStatus;
  final String? blockedReason;
}

Future<void> showTaskEditorDialog({
  required BuildContext context,
  required String workspaceId,
  required String title,
  required String actionLabel,
  required String helperText,
  required Future<void> Function(TaskEditorValues values) onSubmit,
  TaskItem? initialTask,
}) async {
  final services = AppScope.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return _TaskEditorDialog(
        services: services,
        workspaceId: workspaceId,
        title: title,
        actionLabel: actionLabel,
        helperText: helperText,
        initialTask: initialTask,
        onSubmit: onSubmit,
      );
    },
  );
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({
    required this.services,
    required this.workspaceId,
    required this.title,
    required this.actionLabel,
    required this.helperText,
    required this.onSubmit,
    this.initialTask,
  });

  final AppServices services;
  final String workspaceId;
  final String title;
  final String actionLabel;
  final String helperText;
  final Future<void> Function(TaskEditorValues values) onSubmit;
  final TaskItem? initialTask;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  static const String _unassignedValue = '__unassigned__';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _progressController;
  late final TextEditingController _blockedReasonController;
  late final Future<List<_TaskAssigneeOption>> _assigneeOptionsFuture;

  DateTime? _startDate;
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  ReviewStatus _reviewStatus = ReviewStatus.none;
  String? _assignedTo;
  bool _isBusy = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _progressController = TextEditingController(
      text: (task?.progress ?? 0).toString(),
    );
    _blockedReasonController = TextEditingController(
      text: task?.blockedReason ?? '',
    );
    _startDate = task?.startDate;
    _dueDate = task?.dueDate;
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;
    _reviewStatus = task?.reviewStatus ?? ReviewStatus.none;
    _assignedTo = task?.assignedTo;
    _assigneeOptionsFuture = _loadAssigneeOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _progressController.dispose();
    _blockedReasonController.dispose();
    super.dispose();
  }

  Future<List<_TaskAssigneeOption>> _loadAssigneeOptions() async {
    final members = await widget.services.workspaceRepository
        .watchMembers(widget.workspaceId)
        .first;

    final activeMembers = members
        .where((member) => member.status == WorkspaceMemberStatus.active)
        .toList(growable: false);

    final profiles = await Future.wait(
      activeMembers.map(
        (member) =>
            widget.services.userProfileRepository.fetchProfile(member.userId),
      ),
    );

    final options = <_TaskAssigneeOption>[];
    for (var i = 0; i < activeMembers.length; i++) {
      final member = activeMembers[i];
      final profile = profiles[i];
      options.add(
        _TaskAssigneeOption(
          userId: member.userId,
          role: member.role,
          displayName: _displayNameFor(profile, member.userId),
          email: profile?.email.trim(),
        ),
      );
    }

    options.sort((a, b) {
      final byRole = _roleRank(a.role).compareTo(_roleRank(b.role));
      if (byRole != 0) {
        return byRole;
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    final currentAssignee = _assignedTo;
    final alreadyListed = currentAssignee == null
        ? true
        : options.any((option) => option.userId == currentAssignee);
    if (!alreadyListed && currentAssignee.isNotEmpty) {
      final profile = await widget.services.userProfileRepository.fetchProfile(
        currentAssignee,
      );
      options.insert(
        0,
        _TaskAssigneeOption(
          userId: currentAssignee,
          role: WorkspaceRole.member,
          displayName: _displayNameFor(profile, currentAssignee),
          email: profile?.email.trim(),
        ),
      );
    }

    return options;
  }

  String _displayNameFor(UserProfile? profile, String userId) {
    final displayName = profile?.displayName.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = profile?.email.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Nexora user';
  }

  int _roleRank(WorkspaceRole role) {
    return switch (role) {
      WorkspaceRole.owner => 0,
      WorkspaceRole.admin => 1,
      WorkspaceRole.member => 2,
    };
  }

  Future<void> _pickDate({
    required String helpText,
    required DateTime? currentValue,
    required ValueSetter<DateTime?> onSelected,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: helpText,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: currentValue ?? DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            datePickerTheme: theme.datePickerTheme.copyWith(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.primaryStrong,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.ink;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryStrong;
                }
                return null;
              }),
              todayBackgroundColor: WidgetStateProperty.all(
                AppColors.primarySoft,
              ),
              todayForegroundColor: WidgetStateProperty.all(
                AppColors.primaryStrong,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.xLarge),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isBusy = true;
      _submissionError = null;
    });
    try {
      await widget.onSubmit(
        TaskEditorValues(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedTo: _assignedTo,
          startDate: _startDate,
          dueDate: _dueDate,
          progress: int.tryParse(_progressController.text.trim()) ?? 0,
          priority: _priority,
          status: _status,
          reviewStatus: _reviewStatus,
          blockedReason: _blockedReasonController.text.trim().isEmpty
              ? null
              : _blockedReasonController.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _submissionError = _messageFromError(error));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submissionError = _messageFromError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _messageFromError(Object error) {
    final rawMessage = error is AppException ? error.message : error.toString();

    return switch (rawMessage) {
      'Task title is required.' => context.tr(
        en: 'Task title is required.',
        ar: 'عنوان المهمة مطلوب.',
      ),
      'Task title must be at least 2 characters.' => context.tr(
        en: 'Task title must be at least 2 characters.',
        ar: 'عنوان المهمة يجب أن يكون من حرفين على الأقل.',
      ),
      'Task title must be at most 120 characters.' => context.tr(
        en: 'Task title must be at most 120 characters.',
        ar: 'عنوان المهمة يجب ألا يتجاوز 120 حرفاً.',
      ),
      'Progress must be between 0 and 100.' => context.tr(
        en: 'Progress must be between 0 and 100.',
        ar: 'التقدم يجب أن يكون بين 0 و100.',
      ),
      'Due date cannot be earlier than start date.' => context.tr(
        en: 'Due date cannot be earlier than start date.',
        ar: 'تاريخ الاستحقاق لا يمكن أن يكون قبل تاريخ البدء.',
      ),
      'Assigned user must be an active workspace member.' => context.tr(
        en: 'Assigned user must be an active workspace member.',
        ar: 'المستخدم المكلَّف يجب أن يكون عضوًا نشطًا في مساحة العمل.',
      ),
      'Blocked tasks require a blocked reason.' => context.tr(
        en: 'Blocked tasks require a blocked reason.',
        ar: 'المهام الموقوفة تحتاج إلى سبب واضح للتوقف.',
      ),
      _ => rawMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: screenHeight * 0.9,
          ),
          child: AppSurfaceCard(
            glow: true,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  title: widget.title,
                  subtitle: widget.helperText,
                  onClose: _isBusy ? null : () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_submissionError != null) ...[
                            _DialogErrorBanner(message: _submissionError!),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _EditorSection(
                            title: context.tr(
                              en: 'Core details',
                              ar: 'التفاصيل الأساسية',
                            ),
                            subtitle: context.tr(
                              en: 'Start with a clear title and enough context so execution does not depend on extra chat.',
                              ar: 'ابدأ بعنوان واضح وسياق كافٍ حتى لا يعتمد التنفيذ على محادثات إضافية.',
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: context.tr(
                                      en: 'Task title',
                                      ar: 'عنوان المهمة',
                                    ),
                                    hintText: context.tr(
                                      en: 'Example: Finalize sprint kickoff notes',
                                      ar: 'مثال: إنهاء ملاحظات بدء السبرنت',
                                    ),
                                    helperText: context.tr(
                                      en: 'Keep the title short, direct, and action oriented.',
                                      ar: 'اجعل العنوان قصيرًا ومباشرًا وموجَّهًا للتنفيذ.',
                                    ),
                                  ),
                                  validator: (value) =>
                                      _taskTitleValidator(context, value),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: context.tr(
                                      en: 'Description',
                                      ar: 'الوصف',
                                    ),
                                    hintText: context.tr(
                                      en: 'What should happen, what good looks like, and any context the assignee needs.',
                                      ar: 'ما الذي يجب أن يحدث، وما شكل النتيجة الجيدة، وأي سياق يحتاجه المكلَّف.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _EditorSection(
                            title: context.tr(
                              en: 'Execution settings',
                              ar: 'إعدادات التنفيذ',
                            ),
                            subtitle: context.tr(
                              en: 'These controls define how the task should move, how urgent it is, and whether it needs review.',
                              ar: 'تحدد هذه الإعدادات كيفية سير المهمة ومدى أولويتها وما إذا كانت تحتاج إلى مراجعة.',
                            ),
                            child: Column(
                              children: [
                                _FieldGrid(
                                  children: [
                                    _EnumDropdownField<TaskStatus>(
                                      label: context.tr(
                                        en: 'Status',
                                        ar: 'الحالة',
                                      ),
                                      icon: Icons.flag_outlined,
                                      value: _status,
                                      values: TaskStatus.values,
                                      labelBuilder: (value) =>
                                          value.localizedLabel(context),
                                      onChanged: (value) =>
                                          setState(() => _status = value),
                                    ),
                                    _EnumDropdownField<TaskPriority>(
                                      label: context.tr(
                                        en: 'Priority',
                                        ar: 'الأولوية',
                                      ),
                                      icon: Icons.priority_high_rounded,
                                      value: _priority,
                                      values: TaskPriority.values,
                                      labelBuilder: (value) =>
                                          value.localizedLabel(context),
                                      onChanged: (value) =>
                                          setState(() => _priority = value),
                                    ),
                                    _EnumDropdownField<ReviewStatus>(
                                      label: context.tr(
                                        en: 'Review state',
                                        ar: 'حالة المراجعة',
                                      ),
                                      icon: Icons.rule_folder_outlined,
                                      value: _reviewStatus,
                                      values: ReviewStatus.values,
                                      labelBuilder: (value) =>
                                          value.localizedLabel(context),
                                      onChanged: (value) =>
                                          setState(() => _reviewStatus = value),
                                    ),
                                    TextFormField(
                                      controller: _progressController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: context.tr(
                                          en: 'Progress',
                                          ar: 'التقدم',
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.stacked_line_chart_rounded,
                                        ),
                                        helperText: context.tr(
                                          en: 'Use a value between 0 and 100.',
                                          ar: 'استخدم قيمة بين 0 و100.',
                                        ),
                                        suffixText: '%',
                                      ),
                                      validator: (value) =>
                                          _progressValidator(context, value),
                                    ),
                                  ],
                                ),
                                if (_status == TaskStatus.blocked) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _blockedReasonController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      labelText: context.tr(
                                        en: 'Blocked reason',
                                        ar: 'سبب التوقف',
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.error_outline_rounded,
                                      ),
                                      hintText: context.tr(
                                        en: 'Explain what is blocking progress so the team knows what to unblock next.',
                                        ar: 'اشرح ما الذي يوقف التقدم حتى يعرف الفريق ما الذي يجب فكه أولاً.',
                                      ),
                                    ),
                                    validator: (value) {
                                      if (_status != TaskStatus.blocked) {
                                        return null;
                                      }
                                      return _requiredValidator(context, value);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _EditorSection(
                            title: context.tr(
                              en: 'Ownership and timing',
                              ar: 'الملكية والتوقيت',
                            ),
                            subtitle: context.tr(
                              en: 'Choose the right owner from the workspace and set timing without relying on manual IDs.',
                              ar: 'اختر الشخص المناسب من أعضاء المساحة وحدد التوقيت بدون إدخال معرفات يدوياً.',
                            ),
                            child: Column(
                              children: [
                                FutureBuilder<List<_TaskAssigneeOption>>(
                                  future: _assigneeOptionsFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _LoadingField(
                                        label: context.tr(
                                          en: 'Assignee',
                                            ar: 'المكلَّف',
                                        ),
                                        message: context.tr(
                                          en: 'Loading workspace members...',
                                          ar: 'يتم تحميل أعضاء المساحة...',
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return _LoadingField(
                                        label: context.tr(
                                          en: 'Assignee',
                                            ar: 'المكلَّف',
                                        ),
                                        message: context.tr(
                                          en: 'Could not load members. You can still save without assigning.',
                                          ar: 'تعذّر تحميل الأعضاء. لا يزال بإمكانك الحفظ بدون إسناد.',
                                        ),
                                        icon: Icons.warning_amber_rounded,
                                      );
                                    }

                                    final options =
                                        snapshot.data ??
                                        const <_TaskAssigneeOption>[];
                                    _TaskAssigneeOption? selectedOption;
                                    for (final option in options) {
                                      if (option.userId == _assignedTo) {
                                        selectedOption = option;
                                        break;
                                      }
                                    }

                                    return DropdownButtonFormField<String>(
                                      key: ValueKey<String?>(_assignedTo),
                                      initialValue:
                                          _assignedTo ?? _unassignedValue,
                                      isExpanded: true,
                                      menuMaxHeight: 420,
                                      decoration: InputDecoration(
                                        labelText: context.tr(
                                          en: 'Assignee',
                                            ar: 'المكلَّف',
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_search_outlined,
                                        ),
                                        helperText: selectedOption == null
                                            ? context.tr(
                                                en: 'Leave unassigned if the team has not chosen an owner yet.',
                                                ar: 'اتركها غير مسندة إذا لم يحدد الفريق مسؤولاً بعد.',
                                              )
                                            : _assigneeHelperText(
                                                context,
                                                selectedOption,
                                              ),
                                        helperMaxLines: 2,
                                      ),
                                      items: [
                                        DropdownMenuItem<String>(
                                          value: _unassignedValue,
                                          child: Text(
                                            context.tr(
                                              en: 'Unassigned',
                                              ar: 'غير مسندة',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...options.map(
                                          (option) => DropdownMenuItem<String>(
                                            value: option.userId,
                                            child: Text(
                                              option.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                      selectedItemBuilder: (context) {
                                        return [
                                          Text(
                                            context.tr(
                                              en: 'Unassigned',
                                              ar: 'غير مسندة',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          ...options.map(
                                            (option) => Text(
                                              option.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ];
                                      },
                                      onChanged: (value) {
                                        setState(() {
                                          _assignedTo =
                                              value == null ||
                                                  value == _unassignedValue
                                              ? null
                                              : value;
                                        });
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _FieldGrid(
                                  children: [
                                    _DateFieldCard(
                                      label: context.tr(
                                        en: 'Start date',
                                        ar: 'تاريخ البدء',
                                      ),
                                      caption: context.tr(
                                        en: 'When work should begin',
                                        ar: 'متى يبدأ التنفيذ',
                                      ),
                                      value: _localizedDate(
                                        context,
                                        _startDate,
                                        emptyLabel: context.tr(
                                          en: 'Not scheduled',
                                          ar: 'غير محدد',
                                        ),
                                      ),
                                      icon: Icons.play_circle_outline_rounded,
                                      accentColor: AppColors.member,
                                      onTap: () => _pickDate(
                                        helpText: context.tr(
                                          en: 'Select a start date',
                                          ar: 'اختر تاريخ البدء',
                                        ),
                                        currentValue: _startDate,
                                        onSelected: (value) {
                                          setState(() => _startDate = value);
                                        },
                                      ),
                                      onClear: _startDate == null
                                          ? null
                                          : () => setState(
                                              () => _startDate = null,
                                            ),
                                    ),
                                    _DateFieldCard(
                                      label: context.tr(
                                        en: 'Due date',
                                        ar: 'تاريخ الاستحقاق',
                                      ),
                                      caption: context.tr(
                                        en: 'When this should be ready',
                                        ar: 'متى يجب أن تكون جاهزة',
                                      ),
                                      value: _localizedDate(
                                        context,
                                        _dueDate,
                                        emptyLabel: context.tr(
                                          en: 'No deadline',
                                          ar: 'بدون موعد',
                                        ),
                                      ),
                                      icon: Icons.event_outlined,
                                      accentColor: AppColors.primaryStrong,
                                      onTap: () => _pickDate(
                                        helpText: context.tr(
                                          en: 'Select a due date',
                                          ar: 'اختر تاريخ الاستحقاق',
                                        ),
                                        currentValue: _dueDate,
                                        onSelected: (value) {
                                          setState(() => _dueDate = value);
                                        },
                                      ),
                                      onClear: _dueDate == null
                                          ? null
                                          : () =>
                                                setState(() => _dueDate = null),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.outline),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            context.tr(en: 'Cancel', ar: 'إلغاء'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isBusy ? null : _submit,
                          icon: Icon(
                            _isBusy
                                ? Icons.sync_rounded
                                : Icons.check_circle_outline_rounded,
                          ),
                          label: Text(
                            _isBusy
                                ? context.tr(
                                    en: 'Saving...',
                                    ar: 'جارٍ الحفظ...',
                                  )
                                : widget.actionLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _localizedDate(
    BuildContext context,
    DateTime? value, {
    required String emptyLabel,
  }) {
    if (value == null) {
      return emptyLabel;
    }
    return MaterialLocalizations.of(context).formatCompactDate(value);
  }

  String _assigneeHelperText(BuildContext context, _TaskAssigneeOption option) {
    final email = option.email;
    if (email != null && email.isNotEmpty) {
      return context.tr(
        en: '${option.role.localizedLabel(context)} · $email',
        ar: '${option.role.localizedLabel(context)} · $email',
      );
    }
    return context.tr(
      en: option.role.localizedLabel(context),
      ar: option.role.localizedLabel(context),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton.filledTonal(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _DialogErrorBanner extends StatelessWidget {
  const _DialogErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppRadii.medium,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceGlassStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 520;
        if (useSingleColumn) {
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

class _EnumDropdownField<T> extends StatelessWidget {
  const _EnumDropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<T>(value),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: values
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(
                labelBuilder(option),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

class _DateFieldCard extends StatelessWidget {
  const _DateFieldCard({
    required this.label,
    required this.caption,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String caption;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.medium,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadii.medium,
            border: Border.all(color: AppColors.outline),
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: AppRadii.medium,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(icon, color: accentColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        caption,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.inkMuted,
                    ),
                    if (onClear != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: context.tr(
                          en: 'Clear date',
                          ar: 'مسح التاريخ',
                        ),
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField({
    required this.label,
    required this.message,
    this.icon = Icons.sync_rounded,
  });

  final String label;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadii.medium,
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.inkMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskAssigneeOption {
  const _TaskAssigneeOption({
    required this.userId,
    required this.role,
    required this.displayName,
    this.email,
  });

  final String userId;
  final WorkspaceRole role;
  final String displayName;
  final String? email;
}

String? _requiredValidator(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return context.tr(en: 'Required', ar: 'مطلوب');
  }

  return null;
}

String? _taskTitleValidator(BuildContext context, String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return context.tr(
      en: 'Task title is required.',
      ar: 'عنوان المهمة مطلوب.',
    );
  }

  if (trimmed.length < 2) {
    return context.tr(
      en: 'Use at least 2 characters.',
      ar: 'استخدم حرفين على الأقل.',
    );
  }

  if (trimmed.length > 120) {
    return context.tr(
      en: 'Use 120 characters or fewer.',
      ar: 'استخدم 120 حرفاً أو أقل.',
    );
  }

  return null;
}

String? _progressValidator(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return context.tr(en: 'Required', ar: 'مطلوب');
  }

  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0 || parsed > 100) {
    return context.tr(
      en: 'Use a number between 0 and 100',
      ar: 'استخدم رقماً بين 0 و100',
    );
  }

  return null;
}
