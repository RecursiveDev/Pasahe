import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ph_fare_calculator/src/core/theme/app_theme.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';
import 'package:ph_fare_calculator/src/presentation/screens/splash_screen.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter and register adapters for offline map persistence
  await Hive.initFlutter();
  Hive.registerAdapter(DownloadStatusAdapter());
  Hive.registerAdapter(RegionTypeAdapter());
  Hive.registerAdapter(MapRegionAdapter());

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
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.highContrastNotifier,
      builder: (context, isHighContrast, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: SettingsService.localeNotifier,
          builder: (context, locale, child) {
            return MaterialApp(
              title: 'PH Fare Calculator',
              theme: isHighContrast ? AppTheme.darkTheme : AppTheme.lightTheme,
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
