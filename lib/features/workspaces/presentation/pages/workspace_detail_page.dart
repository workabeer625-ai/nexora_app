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
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/pages/project_detail_page.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../workspace_join/presentation/pages/join_requests_admin_page.dart';
import '../../../workspace_join/presentation/widgets/workspace_invite_panel.dart';
import '../../domain/entities/workspace.dart';

class WorkspaceDetailPage extends StatelessWidget {
  const WorkspaceDetailPage({
    super.key,
    required this.userId,
    required this.workspaceId,
    this.initialTabIndex = 0,
  });

  final String userId;
  final String workspaceId;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<Workspace?>(
      stream: services.workspaceRepository.watchWorkspace(workspaceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppLoadingState(
              message: context.tr(
                en: 'Loading workspace...',
                ar: 'يتم تحميل مساحة العمل...',
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: AppErrorState(message: context.trError(snapshot.error)),
          );
        }

        final workspace = snapshot.data;
        if (workspace == null) {
          return Scaffold(
            body: AppErrorState(
              message: context.tr(
                en: 'Workspace not found.',
                ar: 'لم يتم العثور على مساحة العمل.',
              ),
            ),
          );
        }

        return FutureBuilder<WorkspaceMember?>(
          future: services.workspaceRepository.fetchMember(workspaceId, userId),
          builder: (context, membershipSnapshot) {
            final membership = membershipSnapshot.data;
            final canManage =
                membership?.role == WorkspaceRole.owner ||
                membership?.role == WorkspaceRole.admin;
            final resolvedInitialTabIndex = initialTabIndex < 0
                ? 0
                : initialTabIndex > 2
                ? 2
                : initialTabIndex;

            return DefaultTabController(
              initialIndex: resolvedInitialTabIndex,
              length: 3,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.pageGradient,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            0,
                          ),
                          child: _WorkspaceTopChrome(
                            workspace: workspace,
                            membership: membership,
                            canManage: canManage,
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _ProjectsTab(
                                userId: userId,
                                workspace: workspace,
                                membership: membership,
                                workspaceId: workspaceId,
                                workspaceName: workspace.name,
                                canManage: canManage,
                                onReviewRequests: canManage
                                    ? () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => JoinRequestsAdminPage(
                                            workspaceId: workspace.id,
                                            reviewerUserId: userId,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              _TeamTab(
                                userId: userId,
                                workspace: workspace,
                                membership: membership,
                                canManage: canManage,
                                onReviewRequests: canManage
                                    ? () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => JoinRequestsAdminPage(
                                            workspaceId: workspace.id,
                                            reviewerUserId: userId,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              WorkspaceChatTab(
                                currentUserId: userId,
                                workspace: workspace,
                                canAccess: membership != null,
                                canModerate: canManage,
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
          },
        );
      },
    );
  }
}

class _WorkspaceTopChrome extends StatelessWidget {
  const _WorkspaceTopChrome({
    required this.workspace,
    required this.membership,
    required this.canManage,
  });

  final Workspace workspace;
  final WorkspaceMember? membership;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final roleLabel = membership?.role.localizedLabel(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceGlassStrong.withValues(alpha: 0.92),
      borderColor: AppColors.outlineStrong,
      glow: true,
      child: Column(
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: canManage
                        ? AppColors.adminHeroGradient
                        : AppColors.memberHeroGradient,
                  ),
                  borderRadius: AppRadii.medium,
                  boxShadow: AppShadows.soft,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        en: 'Workspace command layer',
                        ar: 'مركز قيادة المساحة',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      workspace.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppStatusBadge(
                    label: '${workspace.memberCount}',
                    backgroundColor: AppColors.surfaceMuted,
                    foregroundColor: AppColors.ink,
                    maxWidth: 64,
                  ),
                  if (roleLabel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppStatusBadge(
                      label: roleLabel,
                      backgroundColor: canManage
                          ? AppColors.adminSoft
                          : AppColors.memberSoft,
                      foregroundColor: canManage
                          ? AppColors.admin
                          : AppColors.member,
                      maxWidth: 120,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted.withValues(alpha: 0.84),
              borderRadius: AppRadii.large,
              border: Border.all(color: AppColors.outline),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: canManage
                      ? AppColors.adminHeroGradient
                      : AppColors.memberHeroGradient,
                ),
                borderRadius: AppRadii.large,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0B4FAE),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.inkMuted,
              labelStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              unselectedLabelStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  icon: const Icon(Icons.layers_outlined, size: 18),
                  text: context.tr(en: 'Projects', ar: 'المشاريع'),
                ),
                Tab(
                  icon: const Icon(Icons.groups_2_outlined, size: 18),
                  text: context.tr(en: 'Team', ar: 'الفريق'),
                ),
                Tab(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  text: context.tr(en: 'Chat', ar: 'الدردشة'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.workspace,
    required this.membership,
    required this.canManage,
    required this.onReviewRequests,
  });

  final Workspace workspace;
  final WorkspaceMember? membership;
  final bool canManage;
  final VoidCallback? onReviewRequests;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canManage
              ? const <Color>[Color(0xFF103A64), Color(0xFF1654B5)]
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
                      ? context.tr(en: 'Admin view', ar: 'عرض الإدارة')
                      : context.tr(en: 'Member view', ar: 'عرض العضو'),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  leading: canManage
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline_rounded,
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
              workspace.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              workspace.description.isEmpty
                  ? context.tr(
                      en: 'No description has been added to this workspace yet.',
                      ar: 'لم تتم إضافة وصف لمساحة العمل بعد.',
                    )
                  : workspace.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                AppStatusBadge(
                  label: workspace.isArchived
                      ? context.tr(en: 'Archived', ar: 'مؤرشفة')
                      : context.tr(en: 'Active', ar: 'نشطة'),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            if (canManage && onReviewRequests != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.inkOnLight,
                ),
                onPressed: onReviewRequests,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  context.tr(
                    en: 'Review join requests',
                    ar: 'مراجعة طلبات الانضمام',
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

class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab({
    required this.userId,
    required this.workspace,
    required this.membership,
    required this.workspaceId,
    required this.workspaceName,
    required this.canManage,
    required this.onReviewRequests,
  });

  final String userId;
  final Workspace workspace;
  final WorkspaceMember? membership;
  final String workspaceId;
  final String workspaceName;
  final bool canManage;
  final VoidCallback? onReviewRequests;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<List<Project>>(
      stream: services.projectRepository.watchProjects(workspaceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading projects...',
              ar: 'يتم تحميل المشاريع...',
            ),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(message: context.trError(snapshot.error));
        }

        final projects = snapshot.data ?? const <Project>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            _WorkspaceHeader(
              workspace: workspace,
              membership: membership,
              canManage: canManage,
              onReviewRequests: onReviewRequests,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppHintCard(
              title: context.tr(en: 'Projects area', ar: 'مساحة المشاريع'),
              message: context.tr(
                en: 'This tab is where the workspace shifts from context to execution. Members explore delivery; admins also create and shape it.',
                ar: 'هنا تنتقل مساحة العمل من السياق إلى التنفيذ. الأعضاء يتابعون التسليم، والإدارة تنشئ العمل وتشكّله.',
              ),
              accentColor: AppColors.member,
              backgroundColor: AppColors.memberSoft,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (projects.isEmpty)
              AppEmptyState(
                title: context.tr(
                  en: 'No projects yet',
                  ar: 'لا توجد مشاريع بعد',
                ),
                message: canManage
                    ? context.tr(
                        en: 'Create the first project for $workspaceName to define ownership and momentum.',
                        ar: 'أنشئ أول مشروع في $workspaceName لتحديد الملكية وإطلاق الزخم.',
                      )
                    : context.tr(
                        en: 'Projects will appear here once the workspace starts structuring delivery.',
                        ar: 'ستظهر المشاريع هنا عندما تبدأ المساحة بتنظيم التنفيذ.',
                      ),
                icon: Icons.folder_open_rounded,
                action: canManage
                    ? FilledButton.icon(
                        onPressed: () => _showCreateProjectDialog(context),
                        icon: const Icon(Icons.add),
                        label: Text(
                          context.tr(en: 'Create project', ar: 'إنشاء مشروع'),
                        ),
                      )
                    : null,
              )
            else ...[
              AppSectionHeader(
                title: context.tr(en: 'Projects', ar: 'المشاريع'),
                subtitle: context.tr(
                  en: 'Open a project to see task progress, due dates, and execution detail.',
                  ar: 'افتح أي مشروع لرؤية تقدم المهام ومواعيد الاستحقاق وتفاصيل التنفيذ.',
                ),
                trailing: canManage
                    ? FilledButton.icon(
                        onPressed: () => _showCreateProjectDialog(context),
                        icon: const Icon(Icons.add),
                        label: Text(
                          context.tr(en: 'New project', ar: 'مشروع جديد'),
                        ),
                      )
                    : null,
              ),
              ...projects.map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    borderRadius: AppRadii.large,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProjectDetailPage(
                            userId: userId,
                            workspaceId: workspaceId,
                            projectId: project.id,
                          ),
                        ),
                      );
                    },
                    child: AppSurfaceCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  project.description.isEmpty
                                      ? context.tr(
                                          en: 'No description yet.',
                                          ar: 'لا يوجد وصف بعد.',
                                        )
                                      : project.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppStatusBadge(
                            label: project.status.localizedLabel(context),
                            backgroundColor: _projectTint(project.status),
                            foregroundColor: _projectForeground(project.status),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showCreateProjectDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var status = ProjectStatus.active;
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
                await services.projectManagementService.createProject(
                  workspaceId: workspaceId,
                  name: nameController.text,
                  description: descriptionController.text,
                  status: status,
                  createdBy: userId,
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
              title: Text(context.tr(en: 'Create project', ar: 'إنشاء مشروع')),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: context.tr(en: 'Name', ar: 'الاسم'),
                      ),
                      validator: (value) => _requiredValidator(context, value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.tr(en: 'Description', ar: 'الوصف'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<ProjectStatus>(
                      initialValue: status,
                      items: ProjectStatus.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.localizedLabel(context)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => status = value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: context.tr(en: 'Status', ar: 'الحالة'),
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

  Color _projectTint(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planned => AppColors.surfaceMuted,
      ProjectStatus.active => AppColors.primarySoft,
      ProjectStatus.onHold => AppColors.warningSoft,
      ProjectStatus.completed => AppColors.successSoft,
    };
  }

  Color _projectForeground(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.planned => AppColors.ink,
      ProjectStatus.active => AppColors.primary,
      ProjectStatus.onHold => AppColors.warning,
      ProjectStatus.completed => AppColors.success,
    };
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({
    required this.userId,
    required this.workspace,
    required this.membership,
    required this.canManage,
    required this.onReviewRequests,
  });

  final String userId;
  final Workspace workspace;
  final WorkspaceMember? membership;
  final bool canManage;
  final VoidCallback? onReviewRequests;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<List<WorkspaceMember>>(
      stream: services.workspaceRepository.watchMembers(workspace.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading team...',
              ar: 'يتم تحميل الفريق...',
            ),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(message: context.trError(snapshot.error));
        }

        final members = snapshot.data ?? const <WorkspaceMember>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            _WorkspaceHeader(
              workspace: workspace,
              membership: membership,
              canManage: canManage,
              onReviewRequests: onReviewRequests,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: context.tr(en: 'Team', ar: 'الفريق'),
              subtitle: canManage
                  ? context.tr(
                      en: 'Access, membership growth, and invite controls all live here.',
                      ar: 'هنا تجد التحكم بالوصول ونمو العضوية وأدوات الدعوات.',
                    )
                  : context.tr(
                      en: 'See who belongs to this workspace and how the team is structured.',
                      ar: 'شاهد من ينتمي إلى هذه المساحة وكيف يتوزع الفريق.',
                    ),
            ),
            if (canManage) ...[
              AppHintCard(
                title: context.tr(
                  en: 'Admin-only management',
                  ar: 'أدوات الإدارة فقط',
                ),
                message: context.tr(
                  en: 'Share join codes here, then review join requests before membership is created. Members do not see these controls.',
                  ar: 'شارك أكواد الانضمام هنا، ثم راجع الطلبات قبل إنشاء العضوية. الأعضاء لا يرون هذه الأدوات.',
                ),
                accentColor: AppColors.admin,
                backgroundColor: AppColors.adminSoft,
              ),
              const SizedBox(height: AppSpacing.xl),
              WorkspaceInvitePanel(
                workspaceId: workspace.id,
                actorUserId: userId,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (members.isEmpty)
              AppEmptyState(
                title: context.tr(
                  en: 'No members yet',
                  ar: 'لا يوجد أعضاء بعد',
                ),
                message: context.tr(
                  en: 'Approved requests and owner setup will create the first active members here.',
                  ar: 'وسيؤدي قبول الطلبات وإعداد المالك إلى ظهور أول الأعضاء النشطين هنا.',
                ),
                icon: Icons.groups_outlined,
              )
            else
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _WorkspaceMemberCard(member: member),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorkspaceMemberCard extends StatelessWidget {
  const _WorkspaceMemberCard({required this.member});

  final WorkspaceMember member;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<UserProfile?>(
      stream: services.userProfileRepository.watchProfile(member.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final hasDisplayName = profile?.displayName.trim().isNotEmpty == true;
        final displayName = hasDisplayName
            ? profile!.displayName.trim()
            : context.tr(en: 'Workspace member', ar: 'عضو مساحة العمل');
        final email = profile?.email.trim();
        final secondaryLabel = email != null && email.isNotEmpty
            ? email
            : context.tr(
                en: member.role.localizedLabel(context),
                ar: member.role.localizedLabel(context),
              );
        final roleBackground = member.role == WorkspaceRole.member
            ? AppColors.memberSoft
            : AppColors.adminSoft;
        final roleForeground = member.role == WorkspaceRole.member
            ? AppColors.member
            : AppColors.admin;

        return AppSurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      roleForeground.withValues(alpha: 0.94),
                      AppColors.primaryStrong,
                    ],
                  ),
                  borderRadius: AppRadii.medium,
                ),
                child: Text(
                  _workspaceMemberInitials(displayName),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      secondaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.tr(
                        en: 'Status: ${member.status.localizedLabel(context)}',
                        ar: 'الحالة: ${member.status.localizedLabel(context)}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppStatusBadge(
                    label: member.role.localizedLabel(context),
                    backgroundColor: roleBackground,
                    foregroundColor: roleForeground,
                    maxWidth: 108,
                  ),
                  if (member.status == WorkspaceMemberStatus.active) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppStatusBadge(
                      label: context.tr(en: 'Active member', ar: 'عضو نشط'),
                      backgroundColor: AppColors.successSoft,
                      foregroundColor: AppColors.success,
                      maxWidth: 112,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _workspaceMemberInitials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'N';
  }
  if (parts.length == 1) {
    final value = parts.first;
    return value.length >= 2
        ? value.substring(0, 2).toUpperCase()
        : value.substring(0, 1).toUpperCase();
  }
  final first = parts.first.substring(0, 1).toUpperCase();
  final second = parts.last.substring(0, 1).toUpperCase();
  return first + second;
}

String? _requiredValidator(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return context.tr(en: 'Required', ar: 'مطلوب');
  }

  return null;
}
