import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nexora_app/app/pages/app_shell_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShellPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to Nexora",
          body: "The best application to manage your projects and collaborate with your team.",
          image: const Center(child: Icon(Icons.waving_hand, size: 50.0)),
        ),
        PageViewModel(
          title: "Collaborate in Workspaces",
          body: "Create or join workspaces to share progress and manage tasks with others.",
          image: const Center(child: Icon(Icons.group, size: 50.0)),
        ),
        PageViewModel(
          title: "Scan & Go",
          body: "Use the built-in scanner to quickly manage assets and items using QR codes.",
          image: const Center(child: Icon(Icons.qr_code_scanner, size: 50.0)),
        ),
      ],
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
