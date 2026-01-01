import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_calculator/src/presentation/controllers/main_screen_controller.dart';
import 'package:ph_fare_calculator/src/presentation/screens/onboarding_screen.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:ph_fare_calculator/src/core/hybrid_engine.dart';
import 'package:ph_fare_calculator/src/services/routing/routing_service.dart';

import '../helpers/mocks.dart';
import 'main_screen_test.dart';

class FakeSettingsService extends MockSettingsService {
  Locale _locale = const Locale('en');
  @override
  Future<Locale> getLocale() async => _locale;
  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    SettingsService.localeNotifier.value = locale;
  }
}

void main() {
  late FakeSettingsService fakeSettingsService;

  setUp(() async {
    final getIt = GetIt.instance;
    await getIt.reset();
    fakeSettingsService = FakeSettingsService();
    getIt.registerSingleton<SettingsService>(fakeSettingsService);
    
    // Register other dependencies needed for MainScreen if it gets built
    getIt.registerSingleton<FareRepository>(MockFareRepository());
    getIt.registerSingleton<GeocodingService>(MockGeocodingService());
    getIt.registerSingleton<RoutingService>(MockRoutingService());
    getIt.registerSingleton<HybridEngine>(MockHybridEngine());
    getIt.registerSingleton<FareComparisonService>(MockFareComparisonService());
    getIt.registerSingleton<ConnectivityService>(MockConnectivityService());
    getIt.registerSingleton<OfflineModeService>(MockOfflineModeService());
    getIt.registerSingleton<OfflineMapService>(MockOfflineMapService());
    
    getIt.registerSingleton<RoutingRepository>(
      RoutingRepository(
        getIt<RoutingService>(),
        MockRouteCacheService(),
        MockTrainFerryGraphService(),
        getIt<RoutingService>(),
        getIt<ConnectivityService>(),
        getIt<OfflineModeService>(),
      ),
    );
    
    getIt.registerSingleton<MainScreenController>(
      MainScreenController(
        getIt<GeocodingService>(),
        getIt<HybridEngine>(),
        getIt<FareRepository>(),
        getIt<RoutingRepository>(),
        getIt<SettingsService>(),
        getIt<FareComparisonService>(),
        getIt<OfflineModeService>(),
      ),
    );

  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return ValueListenableBuilder<Locale>(
      valueListenable: SettingsService.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        );
      },
    );
  }

  testWidgets('Language selection in onboarding updates app locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify initial language is English (on first page)
    expect(
      find.textContaining('Calculate fares for jeepneys', skipOffstage: false),
      findsOneWidget,
    );

    // Go to last page (Language Selection) - 2 clicks for 3 pages
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Find and tap the Tagalog card (it should be visible on Page 3)
    final tagalogCard = find.text('Tagalog');
    await tester.scrollUntilVisible(
      tagalogCard,
      100.0,
      scrollable: find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(tagalogCard);
    await tester.pumpAndSettle();

    // Swipe back to first page to check translated text
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    // Verify language changed to Tagalog
    expect(
      find.textContaining('Kalkulahin ang pamasahe para sa jeepney', skipOffstage: false),
      findsOneWidget,
    );
    
    // Verify it persisted in settings
    final locale = await fakeSettingsService.getLocale();
    expect(locale.languageCode, 'tl');
  });
}
