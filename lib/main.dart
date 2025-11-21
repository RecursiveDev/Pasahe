import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ph_fare_estimator/src/models/fare_formula.dart';
import 'package:ph_fare_estimator/src/models/fare_result.dart';
import 'package:ph_fare_estimator/src/models/saved_route.dart';
import 'package:ph_fare_estimator/src/presentation/screens/main_screen.dart';
import 'package:ph_fare_estimator/src/presentation/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:ph_fare_estimator/src/services/remote_config_service.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with demo project options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await RemoteConfigService(FirebaseRemoteConfig.instance).initialize();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(FareFormulaAdapter());
  Hive.registerAdapter(SavedRouteAdapter());
  Hive.registerAdapter(FareResultAdapter());
  Hive.registerAdapter(IndicatorLevelAdapter());

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  // Initialize settings
  final settingsService = SettingsService();
  await settingsService.getHighContrastEnabled();

  runApp(MyApp(hasCompletedOnboarding: hasCompletedOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasCompletedOnboarding;

  const MyApp({
    super.key,
    required this.hasCompletedOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.cyanAccent,
        secondary: Colors.yellowAccent,
        surface: Colors.black,
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
      ),
      cardTheme: const CardThemeData(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent, width: 3.0),
        ),
        labelStyle: TextStyle(color: Colors.white),
      ),
      useMaterial3: true,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.highContrastNotifier,
      builder: (context, isHighContrast, child) {
        return MaterialApp(
          title: 'PH Fare Estimator',
          theme: isHighContrast ? darkTheme : lightTheme,
          home: hasCompletedOnboarding ? const MainScreen() : const SplashScreen(),
        );
      },
    );
  }
}