import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_surface_card.dart';

/// Sign-in / sign-up screen.
///
/// A single compact card with the form first: no showcase panels, no
/// marketing copy. Opened from the welcome screen and from the guest
/// join-preview flow, so the [initialTabIndex] contract is preserved.
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
    return context.trError(error);
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
    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(
            context.tr(en: 'Welcome to Nexora', ar: 'مرحبًا بك في Nexora'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AppSurfaceCard(
                  backgroundColor: AppColors.surface.withValues(alpha: 0.96),
                  borderColor: AppColors.primaryStrong.withValues(alpha: 0.14),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTabBar(context),
                      const SizedBox(height: AppSpacing.xl),
                      _AuthTabSwitcher(
                        children: [
                          _buildLoginForm(context),
                          _buildSignupForm(context),
                        ],
                      ),
                    ],
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
            Tab(text: context.tr(en: 'Sign in', ar: 'تسجيل الدخول')),
            Tab(text: context.tr(en: 'Create account', ar: 'إنشاء حساب')),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return _AuthForm(
      formKey: _loginFormKey,
      buttonText: context.tr(en: 'Sign in', ar: 'تسجيل الدخول'),
      busy: _isBusy,
      onSubmit: _handleLogin,
      children: [
        TextFormField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Email', ar: 'البريد الإلكتروني'),
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
      buttonText: context.tr(en: 'Create account', ar: 'إنشاء حساب'),
      busy: _isBusy,
      onSubmit: _handleSignup,
      children: [
        TextFormField(
          controller: _signupNameController,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Name', ar: 'الاسم'),
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
              en: 'At least 8 characters.',
              ar: '8 أحرف على الأقل.',
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
    required this.buttonText,
    required this.busy,
    required this.onSubmit,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final String buttonText;
  final bool busy;
  final Future<void> Function() onSubmit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              busy
                  ? context.tr(en: 'Please wait...', ar: 'يرجى الانتظار...')
                  : buttonText,
            ),
          ),
        ],
      ),
    );
  }
}
