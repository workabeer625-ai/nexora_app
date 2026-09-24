import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nexora_app/app/pages/app_shell_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';

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
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: context.tr(en: 'Welcome to Nexora', ar: 'مرحبًا بك في Nexora'),
          body: context.tr(
            en: 'Manage projects and collaborate with your team in one calm workspace.',
            ar: 'أدر مشاريعك وتعاون مع فريقك في مساحة عمل واحدة ومنظمة.',
          ),
          image: const Center(child: Icon(Icons.waving_hand, size: 50.0)),
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
          image: const Center(child: Icon(Icons.group, size: 50.0)),
        ),
        PageViewModel(
          title: context.tr(en: 'Join in seconds', ar: 'انضم خلال ثوانٍ'),
          body: context.tr(
            en: 'Use an invite code or scan a QR, preview the workspace, then request access.',
            ar: 'استخدم كود الدعوة أو امسح رمز QR، وعاين المساحة، ثم اطلب الوصول.',
          ),
          image: const Center(child: Icon(Icons.qr_code_scanner, size: 50.0)),
        ),
      ],
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      skip: Text(
        context.tr(en: 'Skip', ar: 'تخطي'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      next: const Icon(Icons.arrow_forward),
      done: Text(
        context.tr(en: 'Done', ar: 'تم'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
