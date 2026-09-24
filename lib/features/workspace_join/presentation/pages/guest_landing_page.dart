import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_brand_icon.dart';
import '../../../../shared/widgets/app_chrome_background.dart';
import '../../../../shared/widgets/app_floating_nav_bar.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import 'join_with_code_page.dart';
import 'scan_join_qr_page.dart';

class GuestLandingPage extends StatefulWidget {
  const GuestLandingPage({super.key});

  @override
  State<GuestLandingPage> createState() => _GuestLandingPageState();
}

class _GuestLandingPageState extends State<GuestLandingPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppChromeBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 132),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentIndex),
                        child: _buildSection(context),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 18,
                end: 18,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: AppFloatingNavBar(
                        destinations: _guestDestinations(context),
                        selectedIndex: _currentIndex,
                        onSelect: (value) =>
                            setState(() => _currentIndex = value),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    switch (_currentIndex) {
      case 1:
        return _SectionPage(
          key: const PageStorageKey<String>('journey'),
          eyebrow: context.tr(en: 'Journey', ar: 'الرحلة'),
          title: context.tr(
            en: 'Guests preview. Members execute. Admins control.',
            ar: 'الضيف يعاين. العضو ينفذ. الإدارة تتحكم.',
          ),
          subtitle: context.tr(
            en: 'A clearer role split makes the whole product easier to understand.',
            ar: 'تقسيم الأدوار بوضوح يجعل فهم المنتج أسهل بكثير.',
          ),
          children: [
            AppResponsiveWrapGrid(
              minItemWidth: 280,
              maxColumns: 3,
              children: [
                _InfoCard(
                  icon: Icons.person_search_rounded,
                  title: context.tr(en: 'Guest', ar: 'ضيف'),
                  body: context.tr(
                    en: 'Explore safely, then join by code or QR when ready.',
                    ar: 'استكشف بأمان، ثم انضم بالكود أو QR عندما تصبح جاهزًا.',
                  ),
                  tone: AppColors.infoSoft,
                ),
                _InfoCard(
                  icon: Icons.task_alt_rounded,
                  title: context.tr(en: 'Member', ar: 'عضو'),
                  body: context.tr(
                    en: 'Focus on tasks and workspace context without admin clutter.',
                    ar: 'ركّز على المهام وسياق المساحة بدون ازدحام إداري.',
                  ),
                  tone: AppColors.primarySoft,
                ),
                _InfoCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: context.tr(en: 'Admin', ar: 'إدارة'),
                  body: context.tr(
                    en: 'Approve requests and keep access deliberate and controlled.',
                    ar: 'وافق على الطلبات وحافظ على وصول منظم ومضبوط.',
                  ),
                  tone: AppColors.adminSoft,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSurfaceCard(
              child: AppResponsiveWrapGrid(
                minItemWidth: 250,
                maxColumns: 4,
                children: [
                  _StepCard(
                    step: '01',
                    text: context.tr(
                      en: 'Receive a code or QR from the workspace owner.',
                      ar: 'استلم كودًا أو QR من مالك المساحة.',
                    ),
                  ),
                  _StepCard(
                    step: '02',
                    text: context.tr(
                      en: 'Preview the workspace safely before entering.',
                      ar: 'عاين المساحة بأمان قبل الدخول.',
                    ),
                  ),
                  _StepCard(
                    step: '03',
                    text: context.tr(
                      en: 'Sign in and submit a join request.',
                      ar: 'سجّل الدخول وأرسل طلب انضمام.',
                    ),
                  ),
                  _StepCard(
                    step: '04',
                    text: context.tr(
                      en: 'Wait for admin approval to activate access.',
                      ar: 'انتظر موافقة الإدارة لتفعيل الوصول.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
        return _SectionPage(
          key: const PageStorageKey<String>('join'),
          eyebrow: context.tr(en: 'Join', ar: 'الانضمام'),
          title: context.tr(
            en: 'Pick the access method that fits your situation.',
            ar: 'اختر طريقة الوصول المناسبة لحالتك.',
          ),
          subtitle: context.tr(
            en: 'Code and QR stay prominent, but account setup is still one tap away.',
            ar: 'الكود وQR واضحان، وإنشاء الحساب ما زال على بُعد لمسة واحدة.',
          ),
          children: [
            AppResponsiveWrapGrid(
              minItemWidth: 280,
              maxColumns: 3,
              children: [
                _ActionCard(
                  icon: Icons.password_rounded,
                  title: context.tr(en: 'Join with code', ar: 'انضمام بالكود'),
                  body: context.tr(
                    en: 'Paste the invite code, preview the workspace, then request access.',
                    ar: 'ألصق كود الدعوة، عاين المساحة، ثم اطلب الوصول.',
                  ),
                  primaryLabel: context.tr(
                    en: 'Open code entry',
                    ar: 'فتح إدخال الكود',
                  ),
                  onPrimary: () => _openPage(context, const JoinWithCodePage()),
                ),
                _ActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: context.tr(en: 'Scan QR', ar: 'مسح QR'),
                  body: context.tr(
                    en: 'Use the camera for the fastest path when a QR is available.',
                    ar: 'استخدم الكاميرا لأسرع مسار عند توفر رمز QR.',
                  ),
                  primaryLabel: context.tr(
                    en: 'Open scanner',
                    ar: 'فتح الماسح',
                  ),
                  onPrimary: () => _openPage(context, const ScanJoinQrPage()),
                ),
                _ActionCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: context.tr(
                    en: 'Need an account first?',
                    ar: 'تحتاج حسابًا أولاً؟',
                  ),
                  body: context.tr(
                    en: 'Create your identity now, then come back here and complete the join flow.',
                    ar: 'أنشئ هويتك الآن، ثم عد هنا لإكمال مسار الانضمام.',
                  ),
                  primaryLabel: context.tr(
                    en: 'Create account',
                    ar: 'إنشاء حساب',
                  ),
                  secondaryLabel: context.tr(en: 'Sign in', ar: 'تسجيل الدخول'),
                  onPrimary: () => _openAuth(context, initialTabIndex: 1),
                  onSecondary: () => _openAuth(context, initialTabIndex: 0),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppHintCard(
              title: context.tr(
                en: 'Before you request access',
                ar: 'قبل إرسال طلب الوصول',
              ),
              message: context.tr(
                en: 'Use codes only from workspace owners or admins, and read the preview carefully before continuing.',
                ar: 'استخدم الأكواد من مالك المساحة أو الإدارة فقط، واقرأ المعاينة جيدًا قبل المتابعة.',
              ),
              accentColor: AppColors.primary,
              backgroundColor: AppColors.infoSoft,
            ),
          ],
        );
      case 3:
        return _SectionPage(
          key: const PageStorageKey<String>('access'),
          eyebrow: context.tr(en: 'Access', ar: 'الدخول'),
          title: context.tr(
            en: 'Move from guest mode into the real workspace flow.',
            ar: 'انتقل من وضع الضيف إلى مسار العمل الحقيقي.',
          ),
          subtitle: context.tr(
            en: 'Use sign in if your identity already exists, or create a fresh account first.',
            ar: 'استخدم تسجيل الدخول إذا كانت هويتك موجودة، أو أنشئ حسابًا جديدًا أولاً.',
          ),
          children: [
            AppResponsiveWrapGrid(
              minItemWidth: 280,
              maxColumns: 2,
              children: [
                _ActionCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: context.tr(en: 'Create account', ar: 'إنشاء حساب'),
                  body: context.tr(
                    en: 'Best for first-time users who need a Nexora identity before joining a workspace.',
                    ar: 'مناسب للمستخدم الجديد الذي يحتاج هوية Nexora قبل الانضمام إلى مساحة عمل.',
                  ),
                  primaryLabel: context.tr(
                    en: 'Start setup',
                    ar: 'ابدأ الإعداد',
                  ),
                  onPrimary: () => _openAuth(context, initialTabIndex: 1),
                ),
                _ActionCard(
                  icon: Icons.login_rounded,
                  title: context.tr(en: 'Sign in', ar: 'تسجيل الدخول'),
                  body: context.tr(
                    en: 'Best if you already have an account and want to continue or request access.',
                    ar: 'مناسب إذا كان لديك حساب بالفعل وتريد المتابعة أو طلب الوصول.',
                  ),
                  primaryLabel: context.tr(
                    en: 'Open sign in',
                    ar: 'فتح تسجيل الدخول',
                  ),
                  onPrimary: () => _openAuth(context, initialTabIndex: 0),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSurfaceCard(
              backgroundColor: AppColors.warningSoft,
              borderColor: AppColors.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      en: 'Already holding an invite?',
                      ar: 'لديك دعوة جاهزة؟',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr(
                      en: 'Switch to the Join tab below when you want to use a code or QR.',
                      ar: 'انتقل إلى تبويب الانضمام في الأسفل عندما تريد استخدام الكود أو QR.',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        );
      case 0:
      default:
        return _SectionPage(
          key: const PageStorageKey<String>('overview'),
          eyebrow: '',
          title: '',
          subtitle: '',
          topOnly: true,
          children: [
            _HeroCard(
              onCreateAccount: () => _openAuth(context, initialTabIndex: 1),
              onSignIn: () => _openAuth(context, initialTabIndex: 0),
              onJoinWithCode: () =>
                  _openPage(context, const JoinWithCodePage()),
              onScanQr: () => _openPage(context, const ScanJoinQrPage()),
              onExplore: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppResponsiveWrapGrid(
              minItemWidth: 250,
              maxColumns: 3,
              children: [
                _StatCard(
                  icon: Icons.visibility_rounded,
                  title: context.tr(en: 'Safe preview', ar: 'معاينة آمنة'),
                  value: context.tr(
                    en: 'No workspace data exposed',
                    ar: 'بدون كشف بيانات المساحة',
                  ),
                  tone: AppColors.infoSoft,
                ),
                _StatCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: context.tr(en: 'Fast entry', ar: 'دخول سريع'),
                  value: context.tr(
                    en: 'Code or QR in seconds',
                    ar: 'كود أو QR خلال ثوانٍ',
                  ),
                  tone: AppColors.successSoft,
                ),
                _StatCard(
                  icon: Icons.fact_check_rounded,
                  title: context.tr(en: 'Clear approval', ar: 'موافقة واضحة'),
                  value: context.tr(
                    en: 'Admins approve intentionally',
                    ar: 'الإدارة توافق بشكل مقصود',
                  ),
                  tone: AppColors.adminSoft,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppHintCard(
              title: context.tr(
                en: 'Guest mode, simplified',
                ar: 'وضع الضيف بشكل أبسط',
              ),
              message: context.tr(
                en: 'Guest mode shows only what you need to explore, join, and follow up.',
                ar: 'وضع الضيف يعرض فقط ما تحتاجه للاستكشاف والانضمام ومتابعة الطلبات.',
              ),
              accentColor: AppColors.primary,
              backgroundColor: AppColors.infoSoft,
            ),
          ],
        );
    }
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

class _SectionPage extends StatelessWidget {
  const _SectionPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
    this.topOnly = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool topOnly;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (!topOnly) ...[
          AppStatusBadge(
            label: eyebrow,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primaryStrong,
            leading: Icons.grid_view_rounded,
            maxWidth: 180,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
        ],
        ...children,
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onCreateAccount,
    required this.onSignIn,
    required this.onJoinWithCode,
    required this.onScanQr,
    required this.onExplore,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;
  final VoidCallback onJoinWithCode;
  final VoidCallback onScanQr;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.surface,
                AppColors.primarySoft,
                AppColors.adminSoft,
                AppColors.infoSoft,
              ],
            ),
            borderRadius: AppRadii.xLarge,
            border: Border.all(color: AppColors.outlineStrong),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -24,
                right: -18,
                child: _DecorOrb(
                  diameter: 160,
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: -34,
                left: -12,
                child: _DecorOrb(
                  diameter: 170,
                  color: AppColors.info.withValues(alpha: 0.16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Flex(
                  direction: stacked ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: stacked ? 0 : 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppStatusBadge(
                            label: context.tr(
                              en: 'Explore Nexora as a guest',
                              ar: 'استكشف Nexora كضيف',
                            ),
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.ink,
                            leadingWidget: const AppBrandIcon(size: 16),
                            maxWidth: 220,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.tr(
                              en: 'See how Nexora works before you join.',
                              ar: 'تعرّف على Nexora قبل الانضمام.',
                            ),
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.tr(
                              en: 'Browse the main areas, then create an account or join a workspace when you are ready.',
                              ar: 'تصفّح الأقسام الرئيسية، ثم أنشئ حسابًا أو انضم إلى مساحة عندما تكون جاهزًا.',
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              FilledButton.icon(
                                onPressed: onCreateAccount,
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
                              OutlinedButton.icon(
                                onPressed: onJoinWithCode,
                                icon: const Icon(Icons.password_rounded),
                                label: Text(
                                  context.tr(
                                    en: 'Join with code',
                                    ar: 'انضمام بالكود',
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: onScanQr,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: Text(
                                  context.tr(en: 'Scan QR', ar: 'مسح QR'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: onSignIn,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              context.tr(
                                en: 'Already have an account? Sign in',
                                ar: 'لديك حساب بالفعل؟ سجّل الدخول',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: stacked ? 0 : AppSpacing.xl,
                      height: stacked ? AppSpacing.xl : 0,
                    ),
                    Expanded(
                      flex: stacked ? 0 : 5,
                      child: AppSurfaceCard(
                        backgroundColor: AppColors.surfaceGlassStrong,
                        borderColor: AppColors.outlineStrong,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                en: 'What you can do here',
                                ar: 'ماذا يمكنك أن تفعل هنا',
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _BulletRow(
                              text: context.tr(
                                en: 'Preview first, then request access safely.',
                                ar: 'عاين أولاً، ثم اطلب الوصول بأمان.',
                              ),
                            ),
                            _BulletRow(
                              text: context.tr(
                                en: 'Move quickly between the overview, steps, joining, and access.',
                                ar: 'تنقّل بسرعة بين النظرة العامة والخطوات والانضمام والوصول.',
                              ),
                            ),
                            _BulletRow(
                              text: context.tr(
                                en: 'Start clearly without extra steps.',
                                ar: 'ابدأ بوضوح وبدون خطوات زائدة.',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            OutlinedButton.icon(
                              onPressed: onExplore,
                              icon: const Icon(Icons.route_rounded),
                              label: Text(
                                context.tr(
                                  en: 'See how it works',
                                  ar: 'شاهد كيف يعمل',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color tone;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    backgroundColor: tone.withValues(alpha: 0.82),
    borderColor: tone,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryStrong),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });
  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryStrong),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color tone;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    backgroundColor: tone.withValues(alpha: 0.84),
    borderColor: tone,
    child: Row(
      children: [
        Icon(icon, color: AppColors.primaryStrong),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.text});
  final String step;
  final String text;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStatusBadge(
          label: step,
          backgroundColor: AppColors.infoSoft,
          foregroundColor: AppColors.primaryStrong,
          maxWidth: 72,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _DecorOrb extends StatelessWidget {
  const _DecorOrb({required this.diameter, required this.color});
  final double diameter;
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color,
            color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );
}

List<AppFloatingNavDestination> _guestDestinations(BuildContext context) =>
    <AppFloatingNavDestination>[
      AppFloatingNavDestination(
        label: context.tr(en: 'Explore', ar: 'استكشف'),
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
      ),
      AppFloatingNavDestination(
        label: context.tr(en: 'Journey', ar: 'الرحلة'),
        icon: Icons.route_outlined,
        selectedIcon: Icons.route_rounded,
      ),
      AppFloatingNavDestination(
        label: context.tr(en: 'Join', ar: 'انضمام'),
        icon: Icons.hub_outlined,
        selectedIcon: Icons.hub_rounded,
      ),
      AppFloatingNavDestination(
        label: context.tr(en: 'Access', ar: 'دخول'),
        icon: Icons.login_outlined,
        selectedIcon: Icons.login_rounded,
      ),
    ];
