import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_calculator/src/core/constants/region_constants.dart';
import 'package:ph_fare_calculator/src/core/hybrid_engine.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/presentation/controllers/main_screen_controller.dart';
import 'package:ph_fare_calculator/src/presentation/screens/main_screen.dart';
import 'package:ph_fare_calculator/src/presentation/widgets/fare_result_card.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mocks.dart';

// Create a mock for FareComparisonService since it's used in MainScreen
class MockFareComparisonService implements FareComparisonService {
  @override
  List<TransportMode> recommendModes({
    required double distanceInMeters,
    bool isMetroManila = true,
  }) {
    return [];
  }

  @override
  Future<List<FareResult>> compareFares({
    required List<FareResult> fareResults,
    int passengerCount = 1,
    double? originLat,
    double? originLng,
  }) async {
    return fareResults;
  }

  @override
  List<FareResult> sortFares(List<FareResult> results, SortCriteria criteria) {
    return results;
  }

  @override
  Map<TransportMode, List<FareResult>> groupFaresByMode(
    List<FareResult> results,
  ) {
    final grouped = <TransportMode, List<FareResult>>{};
    for (final result in results) {
      final mode = TransportMode.fromString(result.transportMode);
      grouped.putIfAbsent(mode, () => []).add(result);
    }
    return grouped;
  }

  @override
  List<FareResult> filterByRegion(List<FareResult> results, Region region) {
    return results;
  }
}

void main() {
  late MockGeocodingService mockGeocodingService;
  late MockHybridEngine mockHybridEngine;
  late MockFareRepository mockFareRepository;
  late MockRoutingRepository mockRoutingRepo;
  late MockSettingsService mockSettingsService;
  late MockFareComparisonService mockFareComparisonService;
  late MockConnectivityService mockConnectivityService;

  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues({});
    mockGeocodingService = MockGeocodingService();
    mockHybridEngine = MockHybridEngine();
    mockFareRepository = MockFareRepository();
    mockRoutingRepo = MockRoutingRepository();
    mockSettingsService = MockSettingsService();
    mockFareComparisonService = MockFareComparisonService();
    mockConnectivityService = MockConnectivityService();

    // Register mocks with GetIt
    final getIt = GetIt.instance;

    getIt.registerSingleton<GeocodingService>(mockGeocodingService);
    getIt.registerSingleton<RoutingRepository>(mockRoutingRepo);
    getIt.registerSingleton<SettingsService>(mockSettingsService);
    getIt.registerSingleton<HybridEngine>(mockHybridEngine);
    getIt.registerSingleton<FareRepository>(mockFareRepository);
    getIt.registerSingleton<FareComparisonService>(mockFareComparisonService);
    getIt.registerSingleton<ConnectivityService>(mockConnectivityService);
    getIt.registerSingleton<OfflineModeService>(MockOfflineModeService());
    getIt.registerSingleton<OfflineMapService>(MockOfflineMapService());
    getIt.registerSingleton<MainScreenController>(
      MainScreenController(
        mockGeocodingService,
        mockHybridEngine,
        mockFareRepository,
        mockRoutingRepo,
        mockSettingsService,
        mockFareComparisonService,
        getIt<OfflineModeService>(),
      ),
    );

    // Setup default mock behaviors
    mockFareRepository.formulasToReturn = [
      FareFormula(
        mode: 'Jeepney',
        subType: 'Traditional',
        baseFare: 12.0,
        perKmRate: 1.8,
      ),
      FareFormula(
        mode: 'Taxi',
        subType: 'White (Regular)',
        baseFare: 45.0,
        perKmRate: 13.5,
      ),
    ];
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainScreen(),
    );
  }

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('MainScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Initial build

    // Wait for and dismiss the first-time passenger type prompt
    await tester.pump(
      const Duration(milliseconds: 400),
    ); // Wait for dialog delay
    await tester.pumpAndSettle();

    // Dismiss the dialog by selecting Regular
    if (find.text('Welcome to PH Fare Calculator').evaluate().isNotEmpty) {
      await tester.tap(find.text('Regular'));
      await tester.pumpAndSettle();
    }

    expect(find.text('PH Fare Calculator'), findsOneWidget);
    expect(find.text('Origin'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    // New UI uses chip-based passenger selector
    expect(find.text('1 Passenger'), findsOneWidget);
    expect(find.text('Calculate Fare'), findsOneWidget);
  });

  testWidgets('Populates results when Calculate Fare is pressed', (
    WidgetTester tester,
  ) async {
    // Setup larger screen size to accommodate all UI elements
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;

    // Setup data
    final origin = Location(name: 'Luneta', latitude: 14.58, longitude: 120.97);
    final destination = Location(
      name: 'MOA',
      latitude: 14.53,
      longitude: 120.98,
    );

    mockGeocodingService.locationsToReturn = [origin];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Initial build

    // Wait for and dismiss the first-time passenger type prompt
    await tester.pump(
      const Duration(milliseconds: 400),
    ); // Wait for dialog delay
    await tester.pumpAndSettle();

    // Dismiss the dialog by selecting Regular
    if (find.text('Welcome to PH Fare Calculator').evaluate().isNotEmpty) {
      await tester.tap(find.text('Regular'));
      await tester.pumpAndSettle();
    }

    // 1. Search and select Origin
    await tester.enterText(find.widgetWithText(TextField, 'Origin'), 'Luneta');
    await tester.pump(
      const Duration(milliseconds: 900),
    ); // wait for autocomplete debounce (800ms) + buffer
    await tester.pumpAndSettle();
    // Find the option in the dropdown list tile (not the TextField)
    final listTileFinder = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Luneta'),
    );
    if (listTileFinder.evaluate().isNotEmpty) {
      await tester.tap(listTileFinder.first);
    }
    await tester.pumpAndSettle(); // Close options

    // 2. Search and select Destination
    mockGeocodingService.locationsToReturn = [destination];
    await tester.enterText(
      find.widgetWithText(TextField, 'Destination'),
      'MOA',
    );
    await tester.pump(
      const Duration(milliseconds: 900),
    ); // wait for autocomplete debounce (800ms) + buffer
    await tester.pumpAndSettle();
    // Find the option in the dropdown list tile (not the TextField)
    final moaListTileFinder = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('MOA'),
    );
    if (moaListTileFinder.evaluate().isNotEmpty) {
      await tester.tap(moaListTileFinder.first);
    }
    await tester.pumpAndSettle();

    // 3. Tap Calculate
    await tester.tap(find.text('Calculate Fare'));
    await tester.pumpAndSettle();

    // 4. Verify Results
    // Check if error message is showing instead
    expect(find.textContaining('Could not calculate fare'), findsNothing);

    expect(find.byType(FareResultCard), findsWidgets);

    // Reset view size
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
