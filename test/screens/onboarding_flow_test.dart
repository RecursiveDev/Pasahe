import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:ph_fare_calculator/main.dart';
import 'package:ph_fare_calculator/src/core/hybrid_engine.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/models/saved_route.dart';
import 'package:ph_fare_calculator/src/presentation/controllers/main_screen_controller.dart';
import 'package:ph_fare_calculator/src/presentation/screens/main_screen.dart';
import 'package:ph_fare_calculator/src/presentation/screens/onboarding_screen.dart';
import 'package:ph_fare_calculator/src/presentation/screens/splash_screen.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/routing/routing_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../helpers/mocks.dart';
import 'main_screen_test.dart'; // Import MockFareComparisonService from here

void main() {
  late Directory tempDir;
  late MockFareRepository mockFareRepository;
  late MockSettingsService mockSettingsService;
  late MockGeocodingService mockGeocodingService;
  late MockRoutingService mockRoutingService;
  late MockHybridEngine mockHybridEngine;
  late MockFareComparisonService mockFareComparisonService;
  late MockConnectivityService mockConnectivityService;

  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues({});
    
    tempDir = await Directory.systemTemp.createTemp('hive_test_onboarding_');

    // Mock Path Provider for SplashScreen to use the temp dir
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return tempDir.path;
          },
        );

    // Setup mocks
    mockFareRepository = MockFareRepository();
    mockSettingsService = MockSettingsService();
    mockGeocodingService = MockGeocodingService();
    mockRoutingService = MockRoutingService();
    mockHybridEngine = MockHybridEngine();
    mockFareComparisonService = MockFareComparisonService();
    mockConnectivityService = MockConnectivityService();

    // Register mocks - SplashScreen will try to register real ones but catch the error
    // We ensure allowReassignment is false so that configureDependencies throws and we keep our mocks
    GetIt.instance.allowReassignment = false;
    GetIt.instance.registerSingleton<FareRepository>(mockFareRepository);
    GetIt.instance.registerSingleton<SettingsService>(mockSettingsService);
    GetIt.instance.registerSingleton<GeocodingService>(mockGeocodingService);
    GetIt.instance.registerSingleton<RoutingService>(mockRoutingService);
    GetIt.instance.registerSingleton<HybridEngine>(mockHybridEngine);
    GetIt.instance.registerSingleton<FareComparisonService>(
      mockFareComparisonService,
    );
    GetIt.instance.registerSingleton<ConnectivityService>(
      mockConnectivityService,
    );
    GetIt.instance.registerSingleton<OfflineModeService>(MockOfflineModeService());
    GetIt.instance.registerSingleton<OfflineMapService>(MockOfflineMapService());

    GetIt.instance.registerSingleton<RoutingRepository>(
      RoutingRepository(
        mockRoutingService,
        MockRouteCacheService(),
        MockTrainFerryGraphService(),
        mockRoutingService,
        mockConnectivityService,
        GetIt.instance<OfflineModeService>(),
      ),
    );
    GetIt.instance.registerSingleton<MainScreenController>(
      MainScreenController(
        mockGeocodingService,
        mockHybridEngine,
        mockFareRepository,
        GetIt.instance<RoutingRepository>(),
        mockSettingsService,
        mockFareComparisonService,
        GetIt.instance<OfflineModeService>(),
      ),
    );


    // Setup Hive for MainScreen to not crash if it gets built
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FareFormulaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SavedRouteAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FareResultAdapter());
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(IndicatorLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AccuracyLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(RouteSourceAdapter());
    }
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Shows SplashScreen when onboarding is not completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'hasCompletedOnboarding': false});
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    // Handle the Future.delayed navigation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('SplashScreen navigates to OnboardingScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    // The new splash screen uses a bus icon instead of FlutterLogo
    expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);

    // Wait for 2.5 seconds delay (animation duration)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Shows MainScreen when onboarding is completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'hasCompletedOnboarding': true});
    await tester.pumpWidget(const MyApp());

    // Initially shows SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for splash delay and navigation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(MainScreen), findsOneWidget);
  });
}
