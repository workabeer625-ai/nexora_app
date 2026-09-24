import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_loading_state.dart';
import '../../features/home/presentation/pages/admin_dashboard_page.dart';
import '../../features/home/presentation/pages/member_home_page.dart';
import '../../features/home/presentation/pages/my_tasks_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/users/domain/entities/user_profile.dart';
import '../../features/users/presentation/pages/profile_page.dart';
import '../../features/workspace_join/domain/entities/workspace_join_request.dart';
import '../../features/workspace_join/presentation/pages/join_with_code_page.dart';
import '../../features/workspace_join/presentation/pages/join_requests_admin_page.dart';
import '../../features/workspace_join/presentation/pages/scan_join_qr_page.dart';
import '../../features/workspaces/domain/entities/workspace.dart';
import '../../features/workspaces/domain/entities/workspace.dart'
    as workspace_domain;
import '../../features/workspaces/presentation/pages/workspaces_page.dart';
import '../../shared/widgets/app_action_tile.dart';
import '../../shared/widgets/app_chrome_background.dart';
import '../../shared/widgets/app_floating_nav_bar.dart';
import '../../shared/widgets/app_hint_card.dart';
import '../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../shared/widgets/app_section_header.dart';
import '../../shared/widgets/app_status_badge.dart';
import '../../shared/widgets/app_surface_card.dart';
import '../../shared/widgets/workspace_context_card.dart';
import '../app_scope.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _selectedWorkspaceId;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final memberDestinations = _memberDestinations(context);
    final adminDestinations = _adminDestinations(context);

    return StreamBuilder<UserProfile?>(
      stream: services.userProfileRepository.watchProfile(widget.user.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;

        return StreamBuilder<List<Workspace>>(
          stream: services.workspaceRepository.watchUserWorkspaces(
            widget.user.uid,
          ),
          builder: (context, workspaceSnapshot) {
            if (workspaceSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: AppLoadingState(
                  message: context.tr(
                    en: 'Preparing your workspace...',
                    ar: 'جارٍ تجهيز مساحتك...',
                  ),
                ),
              );
            }

            final workspaces = workspaceSnapshot.data ?? const <Workspace>[];
            if (workspaces.isEmpty) {
              return _WorkspaceAccessExperience(
                userId: widget.user.uid,
                profile: profile,
              );
            }

            _syncSelectedWorkspace(workspaces);
            final selectedWorkspace = _workspaceById(
              workspaces,
              _selectedWorkspaceId,
            );

            final membershipStream = selectedWorkspace == null
                ? Stream<workspace_domain.WorkspaceMember?>.value(null)
                : services.workspaceRepository.watchMember(
                    selectedWorkspace.id,
                    widget.user.uid,
                  );

            return StreamBuilder<workspace_domain.WorkspaceMember?>(
              stream: membershipStream,
              builder: (context, membershipSnapshot) {
                final membership = membershipSnapshot.data;
                final isAdminExperience =
                    membership?.role == workspace_domain.WorkspaceRole.owner ||
                    membership?.role == workspace_domain.WorkspaceRole.admin;

                final destinations = isAdminExperience
                    ? adminDestinations
                    : memberDestinations;
                final effectiveIndex = _coerceIndex(destinations.length);
                final topHeader = WorkspaceContextCard(
                  profile: profile,
                  workspaces: workspaces,
                  selectedWorkspaceId: _selectedWorkspaceId,
                  selectedMembership: membership,
                  isAdminExperience: isAdminExperience,
                  onWorkspaceSelected: _handleWorkspaceSelected,
                );

                final pages = isAdminExperience
                    ? <Widget>[
                        AdminDashboardPage(
                          userId: widget.user.uid,
                          selectedWorkspace: selectedWorkspace,
                          onOpenWorkspaces: () => _setIndex(1),
                          onOpenRequests: () => _setIndex(2),
                          topHeader: topHeader,
                        ),
                        WorkspacesPage(
                          userId: widget.user.uid,
                          embedded: true,
                          selectedWorkspaceId: _selectedWorkspaceId,
                          onWorkspaceSelected: _handleWorkspaceSelected,
                        ),
                        selectedWorkspace == null
                            ? const SizedBox.shrink()
                            : JoinRequestsAdminPage(
                                workspaceId: selectedWorkspace.id,
                                reviewerUserId: widget.user.uid,
                                embedded: true,
                              ),
                        NotificationsPage(
                          userId: widget.user.uid,
                          embedded: true,
                        ),
                        ProfilePage(userId: widget.user.uid, embedded: true),
                      ]
                    : <Widget>[
                        MemberHomePage(
                          userId: widget.user.uid,
                          selectedWorkspace: selectedWorkspace,
                          onOpenMyTasks: () => _setIndex(1),
                          onOpenWorkspaceTab: () => _setIndex(2),
                          topHeader: topHeader,
                        ),
                        MyTasksPage(
                          userId: widget.user.uid,
                          selectedWorkspace: selectedWorkspace,
                        ),
                        WorkspacesPage(
                          userId: widget.user.uid,
                          embedded: true,
                          selectedWorkspaceId: _selectedWorkspaceId,
                          onWorkspaceSelected: _handleWorkspaceSelected,
                        ),
                        NotificationsPage(
                          userId: widget.user.uid,
                          embedded: true,
                        ),
                        ProfilePage(userId: widget.user.uid, embedded: true),
                      ];

                return Scaffold(
                  backgroundColor: AppColors.canvas,
                  body: AppChromeBackground(
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: KeyedSubtree(
                                key: ValueKey<String>(
                                  '${isAdminExperience ? 'admin' : 'member'}-$effectiveIndex-${selectedWorkspace?.id ?? 'none'}',
                                ),
                                child: pages[effectiveIndex],
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            start: 18,
                            end: 18,
                            bottom: 18,
                            child: SafeArea(
                              top: false,
                              child: AppFloatingNavBar(
                                destinations: destinations,
                                selectedIndex: effectiveIndex,
                                onSelect: _setIndex,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleWorkspaceSelected(String workspaceId) {
    setState(() {
      _selectedWorkspaceId = workspaceId;
      _currentIndex = 0;
    });
  }

  void _setIndex(int value) {
    setState(() => _currentIndex = value);
  }

  int _coerceIndex(int length) {
    if (length <= 0) {
      return 0;
    }
    if (_currentIndex < length) {
      return _currentIndex;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _currentIndex = 0);
      }
    });
    return 0;
  }

  void _syncSelectedWorkspace(List<Workspace> workspaces) {
    final desiredWorkspaceId = workspaces.isEmpty
        ? null
        : workspaces.any((workspace) => workspace.id == _selectedWorkspaceId)
        ? _selectedWorkspaceId
        : workspaces.first.id;

    if (desiredWorkspaceId == _selectedWorkspaceId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _selectedWorkspaceId = desiredWorkspaceId);
      }
    });
  }

  Workspace? _workspaceById(List<Workspace> workspaces, String? workspaceId) {
    if (workspaceId == null) {
      return workspaces.isEmpty ? null : workspaces.first;
    }

    for (final workspace in workspaces) {
      if (workspace.id == workspaceId) {
        return workspace;
      }
    }

    return workspaces.isEmpty ? null : workspaces.first;
  }
}

class _WorkspaceAccessExperience extends StatelessWidget {
  const _WorkspaceAccessExperience({
    required this.userId,
    required this.profile,
  });

  final String userId;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final displayName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName
        : context.tr(en: 'Nexora user', ar: 'مستخدم Nexora');

    return StreamBuilder<List<WorkspaceJoinRequest>>(
      stream: services.workspaceJoinService.watchUserJoinRequests(userId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <WorkspaceJoinRequest>[];
        final pendingRequests = requests
            .where(
              (request) => request.status == WorkspaceJoinRequestStatus.pending,
            )
            .toList(growable: false);
        final hasPending = pendingRequests.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: AppChromeBackground(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.xxxl),
                          const SizedBox(height: AppSpacing.xxxl),
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 80,
                            color: AppColors.primaryStrong,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.tr(
                              en: 'Welcome to Nexora Tasks',
                              ar: 'مرحبًا بك في مهام نكسورا',
                            ),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.tr(
                              en: 'Manage your projects and collaborate with your team efficiently.\nGet started by creating a new workspace or joining an existing one.',
                              ar: 'أدر مشاريعك وتعاون مع فريقك بكفاءة وسهولة.\nابدأ بإنشاء مساحة عمل جديدة أو الانضمام لمساحة موجودة.',
                            ),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          if (hasPending)
                            AppHintCard(
                              title: context.tr(
                                en: 'Request Pending',
                                ar: 'طلبك قيد الانتظار',
                              ),
                              message: context.tr(
                                en: 'Your join request is waiting for approval. We will notify you once you are in.',
                                ar: 'طلب الانضمام الخاص بك بانتظار موافقة المسؤول. سنقوم بإعلامك فور قبوله.',
                              ),
                              accentColor: AppColors.warning,
                              backgroundColor: AppColors.warningSoft,
                            )
                          else
                            Wrap(
                              spacing: AppSpacing.xl,
                              runSpacing: AppSpacing.xl,
                              alignment: WrapAlignment.center,
                              children: [
                                SizedBox(
                                  width: 320,
                                  child: AppActionTile(
                                    icon: Icons.workspaces_outline,
                                    title: context.tr(
                                      en: 'Create a Workspace',
                                      ar: 'إنشاء مساحة عمل',
                                    ),
                                    description: context.tr(
                                      en: 'Start a new team and invite members.',
                                      ar: 'ابدأ فريقًا جديدًا وقم بدعوة الأعضاء.',
                                    ),
                                    ctaLabel: context.tr(
                                      en: 'Create New',
                                      ar: 'إنشاء جديد',
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => WorkspacesPage(userId: userId),
                                        ),
                                      );
                                    },
                                    badgeLabel: context.tr(
                                      en: 'For Managers',
                                      ar: 'للمدراء',
                                    ),
                                    badgeColor: AppColors.primarySoft,
                                    iconBackground: AppColors.primarySoft,
                                    iconColor: AppColors.primaryStrong,
                                  ),
                                ),
                                SizedBox(
                                  width: 320,
                                  child: AppActionTile(
                                    icon: Icons.qr_code_scanner_rounded,
                                    title: context.tr(
                                      en: 'Join Workspace',
                                      ar: 'الانضمام لمساحة عمل',
                                    ),
                                    description: context.tr(
                                      en: 'Use an invite code or scan a QR.',
                                      ar: 'استخدم كود الدعوة أو امسح رمز QR.',
                                    ),
                                    ctaLabel: context.tr(
                                      en: 'Join Now',
                                      ar: 'انضم الآن',
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const JoinWithCodePage(),
                                        ),
                                      );
                                    },
                                    badgeLabel: context.tr(
                                      en: 'For Team',
                                      ar: 'للفريق',
                                    ),
                                    badgeColor: AppColors.infoSoft,
                                    iconBackground: AppColors.infoSoft,
                                    iconColor: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                        ],
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
  }
}

List<AppFloatingNavDestination> _memberDestinations(BuildContext context) {
  return <AppFloatingNavDestination>[
    AppFloatingNavDestination(
      label: context.tr(en: 'Home', ar: 'الرئيسية'),
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'My Tasks', ar: 'مهامي'),
      icon: Icons.task_outlined,
      selectedIcon: Icons.task_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Workspace', ar: 'المساحة'),
      icon: Icons.workspaces_outline,
      selectedIcon: Icons.workspaces_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Notifications', ar: 'الإشعارات'),
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Profile', ar: 'الملف'),
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];
}

List<AppFloatingNavDestination> _adminDestinations(BuildContext context) {
  return <AppFloatingNavDestination>[
    AppFloatingNavDestination(
      label: context.tr(en: 'Dashboard', ar: 'التحليلات'),
      icon: Icons.auto_graph_outlined,
      selectedIcon: Icons.auto_graph_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Workspaces', ar: 'المساحات'),
      icon: Icons.workspaces_outline,
      selectedIcon: Icons.workspaces_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Requests', ar: 'الطلبات'),
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Notifications', ar: 'الإشعارات'),
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    AppFloatingNavDestination(
      label: context.tr(en: 'Profile', ar: 'الملف'),
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];
}
