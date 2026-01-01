import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ph_fare_calculator/src/core/theme/app_theme.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';
import 'package:ph_fare_calculator/src/presentation/screens/splash_screen.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_cache_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter and register adapters for offline map persistence
  await Hive.initFlutter();
  Hive.registerAdapter(DownloadStatusAdapter());
  Hive.registerAdapter(RegionTypeAdapter());
  Hive.registerAdapter(MapRegionAdapter());
  Hive.registerAdapter(AccuracyLevelAdapter());

  // Initialize dependencies
  await configureDependencies();

  // Pre-initialize static notifiers from SharedPreferences to avoid race condition
  // This ensures ValueListenableBuilders have correct values when the widget tree is built
  final prefs = await SharedPreferences.getInstance();
  final themeMode = prefs.getString('themeMode') ?? 'light';
  final languageCode = prefs.getString('locale') ?? 'en';

  SettingsService.themeModeNotifier.value = themeMode;
  SettingsService.localeNotifier.value = Locale(languageCode);

  // Initialize geocoding cache service
  final geocodingCacheService = getIt<GeocodingCacheService>();
  await geocodingCacheService.initialize();

  // Initialize offline mode service
  final offlineModeService = getIt<OfflineModeService>();
  await offlineModeService.initialize();

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Convert theme mode string to ThemeMode enum
  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.themeModeNotifier,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: SettingsService.localeNotifier,
          builder: (context, locale, child) {
            return MaterialApp(
              title: 'PH Fare Calculator',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: _getThemeMode(themeMode),
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
