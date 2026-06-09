import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool _visible = false;
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();

    // Fade in logo
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _visible = true);
    });

    // Read onboarding flag in parallel (always ready before 2s)
    SharedPreferences.getInstance().then((prefs) {
      _onboardingDone = prefs.getBool('onboarding_done') ?? false;
    });

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        (_onboardingDone ?? false) ? '/dashboard' : '/welcome',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          child: Image.asset('assets/logo/budgetfy_logo.png', width: 360),
        ),
      ),
    );
  }
}
