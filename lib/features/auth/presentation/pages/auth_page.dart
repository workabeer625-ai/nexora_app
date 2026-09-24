import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_chrome_background.dart';
import '../../../../shared/widgets/app_brand_icon.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  bool _isBusy = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.of(context).authCoordinator.signIn(
        email: _loginEmailController.text,
        password: _loginPasswordController.text,
      );
      _closeIfOverlay();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_messageFromError(error))));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.of(context).authCoordinator.signUp(
        email: _signupEmailController.text,
        password: _signupPasswordController.text,
        displayName: _signupNameController.text,
      );
      _closeIfOverlay();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_messageFromError(error))));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return error.toString();
  }

  void _closeIfOverlay() {
    if (!mounted) {
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final shellPadding = viewportWidth < 600 ? AppSpacing.lg : AppSpacing.xl;

    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: AppChromeBackground(
          showGrid: false,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(shellPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 900;
                      final showcase = _AuthShowcasePanel(stacked: stacked);
                      final formCard = _AuthFormCard(
                        tabBar: _buildTabBar(context),
                        content: _AuthTabSwitcher(
                          children: [
                            _buildLoginForm(context),
                            _buildSignupForm(context),
                          ],
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthTopBar(onClose: _closeIfOverlay),
                          const SizedBox(height: AppSpacing.lg),
                          if (stacked) ...[
                            showcase,
                            const SizedBox(height: AppSpacing.xl),
                            formCard,
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 11, child: showcase),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(flex: 10, child: formCard),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.outlineStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primaryStrong,
          unselectedLabelColor: AppColors.inkMuted,
          splashBorderRadius: AppRadii.pill,
          indicator: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.pill,
            boxShadow: AppShadows.soft,
          ),
          tabs: [
            Tab(
              text: context.tr(en: 'Sign in', ar: 'تسجيل الدخول'),
            ),
            Tab(
              text: context.tr(en: 'Create account', ar: 'إنشاء حساب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return _AuthForm(
      formKey: _loginFormKey,
      title: context.tr(en: 'Welcome back', ar: 'مرحبًا بعودتك'),
      subtitle: context.tr(
        en: 'Use your work email and password to continue where you left off.',
        ar: 'استخدم بريد العمل وكلمة المرور للمتابعة من حيث توقفت.',
      ),
      buttonText: context.tr(en: 'Sign in', ar: 'تسجيل الدخول'),
      busy: _isBusy,
      onSubmit: _handleLogin,
      children: [
        TextFormField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Email', ar: 'البريد الإلكتروني'),
            helperText: context.tr(
              en: 'Use the same email linked to your workspace access.',
              ar: 'استخدم نفس البريد المرتبط بوصولك إلى مساحة العمل.',
            ),
            prefixIcon: const Icon(Icons.alternate_email_rounded),
          ),
          validator: _requiredField,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Password', ar: 'كلمة المرور'),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
          ),
          validator: _requiredField,
        ),
      ],
    );
  }

  Widget _buildSignupForm(BuildContext context) {
    return _AuthForm(
      formKey: _signupFormKey,
      title: context.tr(en: 'Create your account', ar: 'أنشئ حسابك'),
      subtitle: context.tr(
        en: 'Create your identity first, then join workspaces and request access safely.',
        ar: 'أنشئ هويتك أولاً، ثم انضم إلى مساحات العمل واطلب الوصول بأمان.',
      ),
      buttonText: context.tr(en: 'Create account', ar: 'إنشاء حساب'),
      busy: _isBusy,
      onSubmit: _handleSignup,
      children: [
        TextFormField(
          controller: _signupNameController,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Display name', ar: 'الاسم الظاهر'),
            helperText: context.tr(
              en: 'This appears in requests, comments, and activity surfaces.',
              ar: 'يظهر هذا الاسم في الطلبات والتعليقات وواجهات النشاط.',
            ),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: _requiredField,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Email', ar: 'البريد الإلكتروني'),
            prefixIcon: const Icon(Icons.alternate_email_rounded),
          ),
          validator: _requiredField,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _signupPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Password', ar: 'كلمة المرور'),
            helperText: context.tr(
              en: 'Use at least 8 characters. Workspace membership comes next.',
              ar: 'استخدم 8 أحرف على الأقل. عضوية مساحة العمل تأتي بعد ذلك.',
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
          ),
          validator: _requiredField,
        ),
      ],
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr(en: 'Required', ar: 'مطلوب');
    }

    return null;
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final canClose = Navigator.of(context).canPop();

    return Row(
      children: [
        AppStatusBadge(
          label: context.tr(en: 'Secure sign in', ar: 'وصول آمن للحساب'),
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primaryStrong,
          leading: Icons.lock_outline_rounded,
          maxWidth: 220,
        ),
        const Spacer(),
        if (canClose)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceGlassStrong,
              borderRadius: AppRadii.pill,
              border: Border.all(color: AppColors.outlineStrong),
            ),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              tooltip: context.tr(en: 'Close', ar: 'إغلاق'),
            ),
          ),
      ],
    );
  }
}

class _AuthShowcasePanel extends StatelessWidget {
  const _AuthShowcasePanel({required this.stacked});

  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.surface.withValues(alpha: 0.98),
            AppColors.adminSoft.withValues(alpha: 0.94),
            AppColors.infoSoft,
          ],
        ),
        borderRadius: AppRadii.xLarge,
        border: Border.all(
          color: AppColors.primaryStrong.withValues(alpha: 0.18),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -24,
            child: _SoftOrb(
              diameter: 180,
              color: AppColors.primaryStrong.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -14,
            child: _SoftOrb(
              diameter: 180,
              color: AppColors.info.withValues(alpha: 0.16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.primaryStrong,
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: AppRadii.large,
                        boxShadow: AppShadows.glow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppBrandIcon(size: stacked ? 52 : 68),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppStatusBadge(
                            label: context.tr(
                              en: 'Work starts here',
                              ar: 'ابدأ من هنا',
                            ),
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primaryStrong,
                            leading: Icons.play_arrow_rounded,
                            maxWidth: 240,
                          ),
                          AppStatusBadge(
                            label: context.tr(
                              en: 'Create account, then join your team',
                              ar: 'أنشئ حسابك ثم انضم لفريقك',
                            ),
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primaryStrong,
                            leading: Icons.arrow_outward_rounded,
                            maxWidth: 240,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppStatusBadge(
                  label: context.tr(en: 'Simple and secure', ar: 'بسيط وآمن'),
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primaryStrong,
                  leading: Icons.shield_outlined,
                  maxWidth: 220,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr(
                    en: 'Sign in faster. Start working sooner.',
                    ar: 'سجّل دخولك بسرعة وابدأ العمل مباشرة.',
                  ),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr(
                    en: 'Create your account or sign in, then join the right workspace with a code, QR, or approval.',
                    ar: 'أنشئ حسابك أو سجّل الدخول، ثم انضم إلى المساحة المناسبة عبر الكود أو QR أو طلب الوصول.',
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppResponsiveWrapGrid(
                  minItemWidth: stacked ? 240 : 250,
                  maxColumns: 2,
                  children: [
                    _AuthSignalCard(
                      icon: Icons.visibility_outlined,
                      title: context.tr(en: 'Clear steps', ar: 'مسار أوضح'),
                      body: context.tr(
                        en: 'Start with your account, then join the workspace.',
                        ar: 'ابدأ بحسابك ثم أكمل الانضمام إلى المساحة.',
                      ),
                      tone: AppColors.primarySoft,
                    ),
                    _AuthSignalCard(
                      icon: Icons.shield_outlined,
                      title: context.tr(en: 'Secure access', ar: 'وصول آمن'),
                      body: context.tr(
                        en: 'Join requests stay clear and easy to track.',
                        ar: 'طلبات الانضمام واضحة وسهلة المتابعة.',
                      ),
                      tone: AppColors.adminSoft,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppHintCard(
                  icon: Icons.route_outlined,
                  title: context.tr(
                    en: 'What happens next',
                    ar: 'ماذا يحدث بعد ذلك',
                  ),
                  message: context.tr(
                    en: 'If your account is already linked to a workspace, you will enter it right away. Otherwise, Nexora helps you create one or join safely.',
                    ar: 'إذا كان حسابك مرتبطًا بمساحة عمل فستدخل إليها مباشرة، وإذا لم يكن كذلك فسيساعدك Nexora على إنشاء مساحة أو الانضمام بأمان.',
                  ),
                  accentColor: AppColors.primaryStrong,
                  backgroundColor: AppColors.primarySoft,
                ),
                if (!stacked) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppSurfaceCard(
                    backgroundColor: AppColors.surface.withValues(alpha: 0.92),
                    borderColor: AppColors.primaryStrong.withValues(
                      alpha: 0.16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            en: 'Everything you need, nothing extra',
                            ar: 'كل ما تحتاجه، بدون تعقيد',
                          ),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _AuthBulletRow(
                          text: context.tr(
                            en: 'Use one account across all your workspaces.',
                            ar: 'حساب واحد لكل مساحاتك.',
                          ),
                        ),
                        _AuthBulletRow(
                          text: context.tr(
                            en: 'Sign in and create your account from the same place.',
                            ar: 'تسجيل الدخول وإنشاء الحساب في مكان واحد.',
                          ),
                        ),
                        _AuthBulletRow(
                          text: context.tr(
                            en: 'Join the right team without extra steps.',
                            ar: 'انضم إلى فريقك الصحيح بدون خطوات زائدة.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({required this.tabBar, required this.content});

  final Widget tabBar;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      backgroundColor: AppColors.surface.withValues(alpha: 0.96),
      borderColor: AppColors.primaryStrong.withValues(alpha: 0.14),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusBadge(
            label: context.tr(
              en: 'Identity & workspace access',
              ar: 'الهوية ووصول مساحة العمل',
            ),
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primaryStrong,
            leading: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr(en: 'Continue with Nexora', ar: 'المتابعة مع Nexora'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              en: 'Choose the path that fits you now. You can create your identity first, then join teams and request access safely.',
              ar: 'اختر المسار المناسب لك الآن. يمكنك إنشاء هويتك أولاً، ثم الانضمام إلى الفرق وطلب الوصول بأمان.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          tabBar,
          const SizedBox(height: AppSpacing.xl),
          content,
        ],
      ),
    );
  }
}

class _AuthSignalCard extends StatelessWidget {
  const _AuthSignalCard({
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
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      backgroundColor: tone.withValues(alpha: 0.82),
      borderColor: tone.withValues(alpha: 0.92),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
                  borderRadius: AppRadii.medium,
                  border: Border.all(
                    color: AppColors.primaryStrong.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: AppColors.primaryStrong),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AuthBulletRow extends StatelessWidget {
  const _AuthBulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
}

class _AuthTabSwitcher extends StatelessWidget {
  const _AuthTabSwitcher({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final safeIndex = tabController.index < children.length
            ? tabController.index
            : children.length - 1;

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: KeyedSubtree(
            key: ValueKey<int>(safeIndex),
            child: children[safeIndex],
          ),
        );
      },
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.busy,
    required this.onSubmit,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool busy;
  final Future<void> Function() onSubmit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          ...children,
          const SizedBox(height: AppSpacing.lg),
          AppHintCard(
            icon: Icons.info_outline_rounded,
            title: context.tr(
              en: 'Why this step matters',
              ar: 'لماذا هذه الخطوة مهمة',
            ),
            message: context.tr(
              en: 'Your account stays separate from workspace permissions, so each team can control who enters.',
              ar: 'حسابك يبقى منفصلًا عن صلاحيات المساحات، لذلك يستطيع كل فريق التحكم بمن يدخل إليه.',
            ),
            accentColor: AppColors.primaryStrong,
            backgroundColor: AppColors.primarySoft,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onSubmit,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                busy
                    ? context.tr(en: 'Please wait...', ar: 'يرجى الانتظار...')
                    : buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
