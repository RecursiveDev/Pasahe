import 'package:flutter/material.dart';
import 'package:ph_fare_estimator/src/presentation/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(size: 100),
      ),
    );
  }
}