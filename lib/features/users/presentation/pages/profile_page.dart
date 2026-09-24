import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_locale_scope.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../domain/entities/user_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId, this.embedded = false});

  final String userId;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = _ProfileView(userId: userId);
    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(en: 'Profile', ar: 'الملف الشخصي')),
      ),
      body: content,
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final localeController = AppLocaleScope.of(context);
    final themeController = AppThemeScope.of(context);

    return StreamBuilder<UserProfile?>(
      stream: services.userProfileRepository.watchProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading profile...',
              ar: 'يتم تحميل الملف الشخصي...',
            ),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(message: context.trError(snapshot.error));
        }

        final profile = snapshot.data;
        if (profile == null) {
          return AppErrorState(
            message: context.tr(
              en: 'Profile not found for this account.',
              ar: 'لم يتم العثور على ملف شخصي لهذا الحساب.',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            AppSectionHeader(
              title: context.tr(en: 'Profile', ar: 'الملف الشخصي'),
              subtitle: context.tr(
                en: 'Your account details, display identity, and sign-out controls.',
                ar: 'تفاصيل حسابك، والهوية المعروضة، وخيارات تسجيل الخروج.',
              ),
              trailing: FilledButton.tonalIcon(
                onPressed: () => _showEditNameDialog(context, profile),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.tr(en: 'Edit name', ar: 'تعديل الاسم')),
              ),
            ),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppStatusBadge(
                        label: profile.role == UserRole.admin
                            ? context.tr(
                                en: 'Global admin account',
                                ar: 'حساب إداري عام',
                              )
                            : context.tr(en: 'Member account', ar: 'حساب عضو'),
                        backgroundColor: profile.role == UserRole.admin
                            ? AppColors.adminSoft
                            : AppColors.memberSoft,
                        foregroundColor: profile.role == UserRole.admin
                            ? AppColors.admin
                            : AppColors.member,
                      ),
                      AppStatusBadge(
                        label: profile.isActive
                            ? context.tr(en: 'Active', ar: 'نشط')
                            : context.tr(en: 'Inactive', ar: 'غير نشط'),
                        backgroundColor: profile.isActive
                            ? AppColors.successSoft
                            : AppColors.errorSoft,
                        foregroundColor: profile.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppHintCard(
              title: context.tr(en: 'Important context', ar: 'معلومة مهمة'),
              message: context.tr(
                en: 'This profile is your account identity. Workspace permissions such as owner, admin, or member are managed separately inside each workspace.',
                ar: 'هذا الملف الشخصي يمثل هوية حسابك. أما صلاحيات مساحة العمل مثل مالك أو مشرف أو عضو فتُدار بشكل مستقل داخل كل مساحة.',
              ),
              accentColor: AppColors.member,
              backgroundColor: AppColors.memberSoft,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: context.tr(en: 'Account details', ar: 'تفاصيل الحساب'),
            ),
            AppSurfaceCard(
              child: Column(
                children: [
                  _ProfileRow(
                    label: context.tr(en: 'Name', ar: 'الاسم'),
                    value: profile.displayName,
                  ),
                  _ProfileRow(
                    label: context.tr(en: 'Email', ar: 'البريد'),
                    value: profile.email,
                  ),
                  _ProfileRow(
                    label: context.tr(en: 'Created', ar: 'تم الإنشاء'),
                    value: AppDateFormatter.dateTimeLocalized(context, profile.createdAt),
                  ),
                  _ProfileRow(
                    label: context.tr(en: 'Updated', ar: 'آخر تحديث'),
                    value: AppDateFormatter.dateTimeLocalized(context, profile.updatedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: context.tr(en: 'Language', ar: 'اللغة'),
              subtitle: context.tr(
                en: 'Choose how the interface should appear on this device. You can keep it on system, Arabic, or English.',
                ar: 'اختر لغة الواجهة على هذا الجهاز: حسب النظام أو العربية أو الإنجليزية.',
              ),
            ),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _PreferenceChip(
                        label: context.tr(en: 'System', ar: 'النظام'),
                        selected:
                            localeController.preference ==
                            AppLanguagePreference.system,
                        onTap: () {
                          localeController.setPreference(
                            AppLanguagePreference.system,
                          );
                        },
                      ),
                      _PreferenceChip(
                        label: context.tr(en: 'Arabic', ar: 'العربية'),
                        selected:
                            localeController.preference ==
                            AppLanguagePreference.arabic,
                        onTap: () {
                          localeController.setPreference(
                            AppLanguagePreference.arabic,
                          );
                        },
                      ),
                      _PreferenceChip(
                        label: context.tr(en: 'English', ar: 'English'),
                        selected:
                            localeController.preference ==
                            AppLanguagePreference.english,
                        onTap: () {
                          localeController.setPreference(
                            AppLanguagePreference.english,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr(
                      en: 'Saved on this device and applied right away.',
                      ar: 'يُحفظ هذا الاختيار على هذا الجهاز ويُطبَّق فورًا.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: context.tr(en: 'Appearance', ar: 'المظهر'),
              subtitle: context.tr(
                en: 'Choose how Nexora should handle light and dark mode on this device.',
                ar: 'اختر مظهر التطبيق على هذا الجهاز.',
              ),
            ),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _PreferenceChip(
                        label: context.tr(en: 'System', ar: 'النظام'),
                        selected:
                            themeController.preference ==
                            AppThemePreference.system,
                        onTap: () {
                          themeController.setPreference(
                            AppThemePreference.system,
                          );
                        },
                      ),
                      _PreferenceChip(
                        label: context.tr(en: 'Light', ar: 'فاتح'),
                        selected:
                            themeController.preference ==
                            AppThemePreference.light,
                        onTap: () {
                          themeController.setPreference(
                            AppThemePreference.light,
                          );
                        },
                      ),
                      _PreferenceChip(
                        label: context.tr(en: 'Dark', ar: 'داكن'),
                        selected:
                            themeController.preference ==
                            AppThemePreference.dark,
                        onTap: () {
                          themeController.setPreference(
                            AppThemePreference.dark,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr(
                      en: 'Saved on this device and applied right away.',
                      ar: 'يُحفظ هذا الاختيار على هذا الجهاز ويُطبَّق فورًا.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: context.tr(en: 'Session', ar: 'الجلسة'),
            ),
            AppSurfaceCard(
              backgroundColor: AppColors.errorSoft,
              borderColor: AppColors.errorSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(en: 'Sign out', ar: 'تسجيل الخروج'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr(
                      en: 'Use this when you are done on a shared device or want to switch to another account.',
                      ar: 'استخدم هذا الخيار عند الانتهاء على جهاز مشترك أو عند الرغبة في التبديل إلى حساب آخر.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: services.authCoordinator.signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(context.tr(en: 'Sign out', ar: 'تسجيل الخروج')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    UserProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.displayName);
    final formKey = GlobalKey<FormState>();
    final services = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final localizeError = context.trError;
    var isBusy = false;

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
                await services.userProfileRepository.updateDisplayName(
                  uid: profile.uid,
                  displayName: controller.text.trim(),
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
                context.tr(en: 'Update display name', ar: 'تحديث الاسم المعروض'),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      en: 'Display name',
                      ar: 'الاسم المعروض',
                    ),
                    helperText: context.tr(
                      en: 'This name appears across comments, requests, and workspace screens.',
                      ar: 'هذا الاسم يظهر في التعليقات والطلبات ومختلف شاشات مساحة العمل.',
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.length < 2) {
                      return context.tr(
                        en: 'Enter at least 2 characters.',
                        ar: 'أدخل حرفين على الأقل.',
                      );
                    }
                    if (trimmed.length > 60) {
                      return context.tr(
                        en: 'Keep it under 60 characters.',
                        ar: 'اجعله أقل من 60 حرفًا.',
                      );
                    }
                    return null;
                  },
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
                        ? context.tr(en: 'Saving...', ar: 'جارٍ الحفظ...')
                        : context.tr(en: 'Save', ar: 'حفظ'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
