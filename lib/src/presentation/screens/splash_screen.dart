import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ph_fare_estimator/src/core/di/injection.dart';
import 'package:ph_fare_estimator/src/models/fare_formula.dart';
import 'package:ph_fare_estimator/src/models/fare_result.dart';
import 'package:ph_fare_estimator/src/models/saved_route.dart';
import 'package:ph_fare_estimator/src/presentation/screens/onboarding_screen.dart';
import 'package:ph_fare_estimator/src/repositories/fare_repository.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';
import 'package:ph_fare_estimator/src/presentation/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Dependency Injection
      try {
        await configureDependencies();
      } catch (e) {
        // In tests, dependencies might be mocked/pre-registered.
        // In prod, this shouldn't fail, but if it does, we log it.
        debugPrint('DI config warning: $e');
      }

      // 2. Local Database (Hive)
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      
      // Wrap adapter registration in try-catch to avoid issues during hot restart or tests
      try {
        if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FareFormulaAdapter());
        if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SavedRouteAdapter());
        if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FareResultAdapter());
        if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(IndicatorLevelAdapter());
      } catch (e) {
        debugPrint('Hive adapter registration warning: $e');
      }

      // 3. Repository Initialization & Seeding
      final fareRepository = getIt<FareRepository>();
      await fareRepository.seedDefaults();

      // 4. Settings
      final settingsService = getIt<SettingsService>();
      await settingsService.getHighContrastEnabled();
      
      // 5. Check Onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

      // Minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => hasCompletedOnboarding
                ? const MainScreen()
                : const OnboardingScreen(),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Show error screen instead of hanging
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Initialization Failed',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
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