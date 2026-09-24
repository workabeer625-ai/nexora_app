import 'package:flutter/material.dart';

import '../../core/localization/app_domain_localizations.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/users/domain/entities/user_profile.dart';
import '../../features/workspaces/domain/entities/workspace.dart';
import 'app_brand_icon.dart';
import 'app_status_badge.dart';
import 'app_surface_card.dart';

class WorkspaceContextCard extends StatelessWidget {
  const WorkspaceContextCard({
    super.key,
    required this.profile,
    required this.workspaces,
    required this.selectedWorkspaceId,
    required this.selectedMembership,
    required this.isAdminExperience,
    required this.onWorkspaceSelected,
  });

  final UserProfile? profile;
  final List<Workspace> workspaces;
  final String? selectedWorkspaceId;
  final WorkspaceMember? selectedMembership;
  final bool isAdminExperience;
  final ValueChanged<String> onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final greetingName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName
        : l10n.text(en: 'Nexora user', ar: 'مستخدم Nexora');

    return AppSurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAdminExperience
                        ? AppColors.adminHeroGradient
                        : AppColors.memberHeroGradient,
                  ),
                  borderRadius: AppRadii.large,
                  boxShadow: AppShadows.glow,
                ),
                child: const AppBrandIcon(size: 56),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppStatusBadge(
                          label: isAdminExperience
                              ? l10n.text(en: 'Admin view', ar: 'عرض الإدارة')
                              : l10n.text(en: 'Member view', ar: 'عرض العضو'),
                          backgroundColor: isAdminExperience
                              ? AppColors.adminSoft
                              : AppColors.memberSoft,
                          foregroundColor: isAdminExperience
                              ? AppColors.admin
                              : AppColors.member,
                        ),
                        if (selectedMembership != null)
                          AppStatusBadge(
                            label: selectedMembership!.role.localizedLabel(
                              context,
                            ),
                            backgroundColor: AppColors.surfaceMuted,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.text(
                        en: 'Welcome back, $greetingName',
                        ar: 'مرحبًا بعودتك، $greetingName',
                      ),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.text(
                        en: 'A calmer command layer with clearer hierarchy, richer signals, and zero visual noise.',
                        ar: 'طبقة تحكم أهدأ، بهرمية أوضح، ومؤشرات أغنى، ودون ضجيج بصري.',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (workspaces.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted.withValues(alpha: 0.92),
                borderRadius: AppRadii.large,
                border: Border.all(color: AppColors.outlineStrong),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            selectedWorkspaceId ?? workspaces.first.id,
                        decoration: InputDecoration(
                          labelText: l10n.text(
                            en: 'Current workspace',
                            ar: 'مساحة العمل الحالية',
                          ),
                          helperText: l10n.text(
                            en: 'Switch workspaces to view its members, tasks, and activity.',
                            ar: 'بدّل بين المساحات لعرض الأعضاء والمهام والنشاط الخاص بكل مساحة.',
                          ),
                        ),
                        items: workspaces
                            .map(
                              (workspace) => DropdownMenuItem(
                                value: workspace.id,
                                child: Text(workspace.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            onWorkspaceSelected(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.large,
                        gradient: LinearGradient(
                          colors: isAdminExperience
                              ? AppColors.adminHeroGradient
                              : AppColors.memberHeroGradient,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${workspaces.length}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            workspaces.length == 1
                                ? l10n.text(en: 'workspace', ar: 'مساحة عمل')
                                : l10n.text(en: 'workspaces', ar: 'مساحات عمل'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
