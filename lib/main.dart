import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/presentation/screens/splash_screen.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize static notifiers from SharedPreferences to avoid race condition
  // This ensures ValueListenableBuilders have correct values when the widget tree is built
  final prefs = await SharedPreferences.getInstance();
  final isHighContrast = prefs.getBool('isHighContrastEnabled') ?? false;
  final languageCode = prefs.getString('locale') ?? 'en';

  SettingsService.highContrastNotifier.value = isHighContrast;
  SettingsService.localeNotifier.value = Locale(languageCode);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        titleLarge: TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
        ),
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
        return ValueListenableBuilder<Locale>(
          valueListenable: SettingsService.localeNotifier,
          builder: (context, locale, child) {
            return MaterialApp(
              title: 'PH Fare Calculator',
              theme: isHighContrast ? darkTheme : lightTheme,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
