import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_plural.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_action_tile.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../workspace_join/presentation/pages/join_with_code_page.dart';
import '../../../workspace_join/presentation/pages/scan_join_qr_page.dart';
import '../../../workspaces/domain/entities/workspace.dart';
import '../../../workspaces/domain/entities/workspace.dart' as workspace_domain;
import 'workspace_detail_page.dart';

class WorkspacesPage extends StatelessWidget {
  const WorkspacesPage({
    super.key,
    required this.userId,
    this.embedded = false,
    this.selectedWorkspaceId,
    this.onWorkspaceSelected,
  });

  final String userId;
  final bool embedded;
  final String? selectedWorkspaceId;
  final ValueChanged<String>? onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    final content = _WorkspacesView(
      userId: userId,
      selectedWorkspaceId: selectedWorkspaceId,
      onWorkspaceSelected: onWorkspaceSelected,
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(en: 'Workspaces', ar: 'مساحات العمل')),
      ),
      body: content,
    );
  }
}

class _WorkspacesView extends StatelessWidget {
  const _WorkspacesView({
    required this.userId,
    required this.selectedWorkspaceId,
    required this.onWorkspaceSelected,
  });

  final String userId;
  final String? selectedWorkspaceId;
  final ValueChanged<String>? onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<List<Workspace>>(
      stream: services.workspaceRepository.watchUserWorkspaces(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading workspaces...',
              ar: 'يتم تحميل مساحات العمل...',
            ),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(message: context.trError(snapshot.error));
        }

        final workspaces = snapshot.data ?? const <Workspace>[];
        final selectedWorkspace = workspaces.firstWhereOrNull(
          (workspace) => workspace.id == selectedWorkspaceId,
        );
        void openSelectedWorkspace({int initialTabIndex = 0}) {
          if (selectedWorkspace == null) {
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WorkspaceDetailPage(
                userId: userId,
                workspaceId: selectedWorkspace.id,
                initialTabIndex: initialTabIndex,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            AppSectionHeader(
              title: context.tr(en: 'Workspaces', ar: 'مساحات العمل'),
              subtitle: context.tr(
                en: 'Switch context, create a new workspace, or join safely with a code or QR.',
                ar: 'بدّل السياق، أنشئ مساحة عمل جديدة، أو انضم بأمان عبر كود أو رمز QR.',
              ),
              trailing: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openJoinWithCode(context),
                    icon: const Icon(Icons.password_rounded),
                    label: Text(
                      context.tr(en: 'Join with code', ar: 'انضمام بالكود'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openScanQr(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(context.tr(en: 'Scan QR', ar: 'مسح QR')),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateWorkspaceDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(
                      context.tr(en: 'New workspace', ar: 'مساحة جديدة'),
                    ),
                  ),
                ],
              ),
            ),
            AppHintCard(
              title: context.tr(en: 'Why this matters', ar: 'لماذا هذا مهم'),
              message: context.tr(
                en: 'A clear workspace switcher keeps member and admin actions scoped. That makes the product easier to trust and easier to understand.',
                ar: 'أداة تبديل مساحة العمل الواضحة تُبقي إجراءات العضو والإدارة ضمن سياقها الصحيح، وهذا يجعل المنتج أوضح وأسهل للوثوق به.',
              ),
              accentColor: AppColors.info,
              backgroundColor: AppColors.infoSoft,
            ),
            if (selectedWorkspace != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppSurfaceCard(
                backgroundColor: AppColors.adminSoft,
                borderColor: AppColors.adminSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              en: 'Current workspace',
                              ar: 'مساحة العمل الحالية',
                            ),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            selectedWorkspace.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            selectedWorkspace.description.isEmpty
                                ? context.tr(
                                    en: 'No description yet.',
                                    ar: 'لا يوجد وصف بعد.',
                                  )
                                : selectedWorkspace.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: openSelectedWorkspace,
                      child: Text(context.tr(en: 'Open', ar: 'فتح')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppResponsiveWrapGrid(
                minItemWidth: 280,
                maxColumns: 2,
                children: [
                  AppActionTile(
                    icon: Icons.arrow_outward_rounded,
                    title: context.tr(
                      en: 'Open workspace detail',
                      ar: 'فتح تفاصيل المساحة',
                    ),
                    description: context.tr(
                      en: 'Jump into projects, team view, and workspace chat from the selected context.',
                      ar: 'ادخل إلى المشاريع وعرض الفريق ودردشة المساحة من السياق المحدد.',
                    ),
                    ctaLabel: context.tr(
                      en: 'Launch detail',
                      ar: 'فتح التفاصيل',
                    ),
                    onPressed: openSelectedWorkspace,
                    badgeLabel: context.tr(
                      en: 'Projects + Team + Chat',
                      ar: 'المشاريع + الفريق + الدردشة',
                    ),
                    badgeColor: AppColors.primarySoft,
                  ),
                  AppActionTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: context.tr(
                      en: 'Open workspace chat',
                      ar: 'فتح دردشة المساحة',
                    ),
                    description: context.tr(
                      en: 'Skip straight to the chat tab when you need team discussion without browsing the other sections first.',
                      ar: 'ادخل مباشرة إلى تبويب الدردشة عندما تحتاج نقاش الفريق دون المرور على بقية الأقسام أولًا.',
                    ),
                    ctaLabel: context.tr(en: 'Open chat', ar: 'فتح الدردشة'),
                    onPressed: () => openSelectedWorkspace(initialTabIndex: 2),
                    badgeLabel: context.tr(
                      en: 'Direct entry',
                      ar: 'دخول مباشر',
                    ),
                    badgeColor: AppColors.infoSoft,
                    iconBackground: AppColors.infoSoft,
                    iconColor: AppColors.info,
                  ),
                  AppActionTile(
                    icon: Icons.password_rounded,
                    title: context.tr(
                      en: 'Join another workspace',
                      ar: 'انضم إلى مساحة أخرى',
                    ),
                    description: context.tr(
                      en: 'Keep adding controlled workspace access by code when you work across multiple teams.',
                      ar: 'أضف وصولًا مضبوطًا لمساحات أخرى عبر الكود عندما تعمل مع أكثر من فريق.',
                    ),
                    ctaLabel: context.tr(
                      en: 'Open join code',
                      ar: 'فتح كود الانضمام',
                    ),
                    onPressed: () => _openJoinWithCode(context),
                    badgeLabel: context.tr(
                      en: 'Multi-workspace',
                      ar: 'متعدد المساحات',
                    ),
                    badgeColor: AppColors.infoSoft,
                    iconBackground: AppColors.infoSoft,
                    iconColor: AppColors.info,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (workspaces.isEmpty)
              AppEmptyState(
                title: context.tr(
                  en: 'No workspaces yet',
                  ar: 'لا توجد مساحات عمل بعد',
                ),
                message: context.tr(
                  en: 'Create your first workspace or join an existing one with a code or QR. Nexora will keep the rest of the experience organized around it.',
                  ar: 'أنشئ أول مساحة عمل أو انضم إلى مساحة موجودة عبر كود أو QR. وسيحافظ Nexora على تنظيم بقية التجربة حولها.',
                ),
                icon: Icons.apartment_rounded,
                action: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showCreateWorkspaceDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(
                        context.tr(
                          en: 'Create workspace',
                          ar: 'إنشاء مساحة عمل',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openJoinWithCode(context),
                      icon: const Icon(Icons.password_rounded),
                      label: Text(
                        context.tr(en: 'Join with code', ar: 'انضمام بالكود'),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...workspaces.map(
                (workspace) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _WorkspaceCard(
                    userId: userId,
                    workspace: workspace,
                    isSelected: workspace.id == selectedWorkspaceId,
                    onSelect: onWorkspaceSelected == null
                        ? null
                        : () => onWorkspaceSelected!(workspace.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openJoinWithCode(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const JoinWithCodePage()));
  }

  Future<void> _openScanQr(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ScanJoinQrPage()));
  }

  Future<void> _showCreateWorkspaceDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var isBusy = false;

    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final localizeError = context.trError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setState(() => isBusy = true);
              try {
                await services.workspaceManagementService.createWorkspace(
                  ownerId: userId,
                  name: nameController.text,
                  description: descriptionController.text,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text(localizeError(error))),
                );
              } finally {
                setState(() => isBusy = false);
              }
            }

            return AlertDialog(
              title: Text(
                context.tr(en: 'Create workspace', ar: 'إنشاء مساحة عمل'),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          en: 'Workspace name',
                          ar: 'اسم مساحة العمل',
                        ),
                        helperText: context.tr(
                          en: 'Choose a name your team will recognize instantly.',
                          ar: 'اختر اسمًا يتعرف عليه فريقك فورًا.',
                        ),
                      ),
                      validator: (value) => _requiredValidator(context, value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.tr(en: 'Description', ar: 'الوصف'),
                        helperText: context.tr(
                          en: 'Optional, but useful for telling members what the workspace is for.',
                          ar: 'اختياري، لكنه مفيد لشرح الغرض من مساحة العمل للأعضاء.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr(en: 'Cancel', ar: 'إلغاء')),
                ),
                FilledButton(
                  onPressed: isBusy ? null : submit,
                  child: Text(
                    isBusy
                        ? context.tr(en: 'Creating...', ar: 'يتم الإنشاء...')
                        : context.tr(en: 'Create', ar: 'إنشاء'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _requiredValidator(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).text(en: 'Required', ar: 'مطلوب');
    }

    return null;
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.userId,
    required this.workspace,
    required this.isSelected,
    required this.onSelect,
  });

  final String userId;
  final Workspace workspace;
  final bool isSelected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<workspace_domain.WorkspaceMember?>(
      stream: services.workspaceRepository.watchMember(workspace.id, userId),
      builder: (context, snapshot) {
        final membership = snapshot.data;

        return InkWell(
          borderRadius: AppRadii.large,
          onTap: onSelect,
          child: AppSurfaceCard(
            backgroundColor: isSelected
                ? AppColors.primarySoft
                : AppColors.surface,
            borderColor: isSelected ? AppColors.primarySoft : AppColors.outline,
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
                            workspace.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            workspace.description.isEmpty
                                ? context.tr(
                                    en: 'No description yet.',
                                    ar: 'لا يوجد وصف بعد.',
                                  )
                                : workspace.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (membership != null)
                      AppStatusBadge(
                        label: membership.role.localizedLabel(context),
                        backgroundColor:
                            membership.role ==
                                workspace_domain.WorkspaceRole.member
                            ? AppColors.memberSoft
                            : AppColors.adminSoft,
                        foregroundColor:
                            membership.role ==
                                workspace_domain.WorkspaceRole.member
                            ? AppColors.member
                            : AppColors.admin,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppStatusBadge(
                      label: context.trCount(
                        workspace.memberCount,
                        enOne: '{n} member',
                        enOther: '{n} members',
                        arZero: 'لا يوجد أعضاء',
                        arOne: 'عضو واحد',
                        arTwo: 'عضوان',
                        arFew: '{n} أعضاء',
                        arMany: '{n} عضوًا',
                      ),
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                    if (isSelected)
                      AppStatusBadge(
                        label: context.tr(
                          en: 'Currently selected',
                          ar: 'المحددة حاليًا',
                        ),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) predicate) {
    for (final value in this) {
      if (predicate(value)) {
        return value;
      }
    }
    return null;
  }
}
