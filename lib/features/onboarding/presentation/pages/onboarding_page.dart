import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nexora_app/app/pages/app_shell_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShellPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = PageDecoration(
      titleTextStyle: theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.25,
      ),
      bodyTextStyle: theme.textTheme.bodyLarge!.copyWith(
        color: AppColors.inkMuted,
        height: 1.7,
      ),
      imagePadding: const EdgeInsets.only(top: 56),
      contentMargin: const EdgeInsets.symmetric(horizontal: 28),
      pageColor: AppColors.canvas,
      footerPadding: const EdgeInsets.only(top: 16),
    );

    return IntroductionScreen(
      globalBackgroundColor: AppColors.canvas,
      pages: [
        PageViewModel(
          title: context.tr(en: 'Welcome to Nexora', ar: 'مرحبًا بك في Nexora'),
          body: context.tr(
            en: 'Manage projects and collaborate with your team in one calm workspace.',
            ar: 'أدر مشاريعك وتعاون مع فريقك في مساحة عمل واحدة ومنظمة.',
          ),
          image: _OnboardingArt(
            gradient: [AppColors.primaryStrong, AppColors.primary],
            glow: AppColors.primary,
            icon: Icons.waving_hand_rounded,
          ),
          decoration: decoration,
        ),
        PageViewModel(
          title: context.tr(
            en: 'Collaborate in Workspaces',
            ar: 'تعاون داخل مساحات العمل',
          ),
          body: context.tr(
            en: 'Create or join workspaces to share progress and manage tasks together.',
            ar: 'أنشئ مساحات عمل أو انضم إليها لمشاركة التقدم وإدارة المهام معًا.',
          ),
          image: _OnboardingArt(
            gradient: AppColors.memberHeroGradient,
            glow: AppColors.member,
            icon: Icons.groups_rounded,
          ),
          decoration: decoration,
        ),
        PageViewModel(
          title: context.tr(en: 'Join in seconds', ar: 'انضم خلال ثوانٍ'),
          body: context.tr(
            en: 'Use an invite code or scan a QR, preview the workspace, then request access.',
            ar: 'استخدم كود الدعوة أو امسح رمز QR، وعاين المساحة، ثم اطلب الوصول.',
          ),
          image: _OnboardingArt(
            gradient: AppColors.adminHeroGradient,
            glow: AppColors.admin,
            icon: Icons.qr_code_scanner_rounded,
          ),
          decoration: decoration,
        ),
      ],
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      showBackButton: true,
      back: const _GhostCircleButton(icon: Icons.arrow_back_rounded),
      skip: Text(
        context.tr(en: 'Skip', ar: 'تخطي'),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.inkMuted,
        ),
      ),
      next: const _GradientCircleButton(),
      done: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryStrong, AppColors.primary],
          ),
          borderRadius: AppRadii.pill,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          context.tr(en: 'Get started', ar: 'ابدأ الآن'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size(8, 8),
        activeSize: const Size(26, 8),
        color: AppColors.outlineStrong,
        activeColor: AppColors.primary,
        spacing: const EdgeInsets.symmetric(horizontal: 4),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      controlsMargin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      controlsPadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
    );
  }
}

/// Large gradient illustration shown at the top of each onboarding page.
class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({
    required this.gradient,
    required this.glow,
    required this.icon,
  });

  final List<Color> gradient;
  final Color glow;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(64)),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.38),
              blurRadius: 44,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: _Orb(diameter: 130, color: Colors.white.withValues(alpha: 0.16)),
            ),
            Positioned(
              bottom: -44,
              left: -24,
              child: _Orb(diameter: 150, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: 34,
              right: 44,
              child: _Orb(diameter: 26, color: Colors.white.withValues(alpha: 0.22)),
            ),
            Center(
              child: Icon(icon, size: 104, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Round gradient "next" button.
class _GradientCircleButton extends StatelessWidget {
  const _GradientCircleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryStrong, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // arrow_forward auto-mirrors in RTL, so "next" stays correct in Arabic.
      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
    );
  }
}

/// Subtle outline "back" button.
class _GhostCircleButton extends StatelessWidget {
  const _GhostCircleButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.outlineStrong),
      ),
      child: Icon(icon, color: AppColors.inkMuted),
    );
  }
}
