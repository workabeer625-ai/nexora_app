import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_brand_icon.dart';
import '../../../../shared/widgets/app_chrome_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import 'join_with_code_page.dart';
import 'scan_join_qr_page.dart';

/// First screen a signed-out user sees.
///
/// A single simple welcome card: sign in, create an account, or join
/// directly with an invite code / QR. No tabs, no marketing sections.
class GuestLandingPage extends StatelessWidget {
  const GuestLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppChromeBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppBrandIcon(size: 76),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Nexora',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.tr(
                        en: 'Tasks, projects, and team chat in one place.',
                        ar: 'المهام والمشاريع ودردشة الفريق في مكان واحد.',
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                _openAuth(context, initialTabIndex: 0),
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              context.tr(
                                en: 'Sign in',
                                ar: 'تسجيل الدخول',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openAuth(context, initialTabIndex: 1),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                            ),
                            label: Text(
                              context.tr(
                                en: 'Create account',
                                ar: 'إنشاء حساب',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            context.tr(
                              en: 'or join directly',
                              ar: 'أو انضم مباشرة',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openPage(
                              context,
                              const JoinWithCodePage(),
                            ),
                            icon: const Icon(Icons.password_rounded),
                            label: Text(
                              context.tr(
                                en: 'Invite code',
                                ar: 'كود الدعوة',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _openPage(context, const ScanJoinQrPage()),
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                            ),
                            label: Text(
                              context.tr(en: 'Scan QR', ar: 'مسح QR'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAuth(BuildContext context, {required int initialTabIndex}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthPage(initialTabIndex: initialTabIndex),
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
