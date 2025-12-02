import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:ph_fare_estimator/src/core/di/injection.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ph_fare_estimator/src/presentation/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.welcomeTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<Locale>(
                valueListenable: SettingsService.localeNotifier,
                builder: (context, currentLocale, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Select English language',
                          button: true,
                          child: currentLocale.languageCode == 'en'
                              ? FilledButton(
                                  onPressed: () {
                                    getIt<SettingsService>()
                                        .setLocale(const Locale('en'));
                                  },
                                  child: const Text('English'),
                                )
                              : OutlinedButton(
                                  onPressed: () {
                                    getIt<SettingsService>()
                                        .setLocale(const Locale('en'));
                                  },
                                  child: const Text('English'),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Select Tagalog language',
                          button: true,
                          child: currentLocale.languageCode == 'tl'
                              ? FilledButton(
                                  onPressed: () {
                                    getIt<SettingsService>()
                                        .setLocale(const Locale('tl'));
                                  },
                                  child: const Text('Tagalog'),
                                )
                              : OutlinedButton(
                                  onPressed: () {
                                    getIt<SettingsService>()
                                        .setLocale(const Locale('tl'));
                                  },
                                  child: const Text('Tagalog'),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.disclaimer,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Semantics(
                label: 'Complete onboarding and continue to main screen',
                button: true,
                child: FilledButton(
                  onPressed: _completeOnboarding,
                  child: Text(AppLocalizations.of(context)!.continueButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}