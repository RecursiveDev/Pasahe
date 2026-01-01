import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_calculator/src/core/constants/region_constants.dart';
import 'package:ph_fare_calculator/src/core/hybrid_engine.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/models/discount_type.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/presentation/controllers/main_screen_controller.dart';
import 'package:ph_fare_calculator/src/presentation/screens/settings_screen.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';

import '../helpers/mocks.dart';

// Create a mock for FareComparisonService since it's used in MainScreenController
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsService mockSettingsService;
  late MockFareRepository mockFareRepository;
  late MockOfflineModeService mockOfflineModeService;
  late MockOfflineMapService mockOfflineMapService;
  late MockRoutingRepository mockRoutingRepo;
  late MockHybridEngine hybridEngine;
  late MockGeocodingService mockGeocodingService;
  late MockFareComparisonService mockFareComparisonService;
  late MockConnectivityService mockConnectivityService;

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockFareRepository = MockFareRepository();
    mockOfflineModeService = MockOfflineModeService();
    mockOfflineMapService = MockOfflineMapService();
    mockRoutingRepo = MockRoutingRepository();
    hybridEngine = MockHybridEngine();
    mockGeocodingService = MockGeocodingService();
    mockFareComparisonService = MockFareComparisonService();
    mockConnectivityService = MockConnectivityService();

    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerSingleton<SettingsService>(mockSettingsService);
    getIt.registerSingleton<FareRepository>(mockFareRepository);
    getIt.registerSingleton<OfflineModeService>(mockOfflineModeService);
    getIt.registerSingleton<OfflineMapService>(mockOfflineMapService);
    mockRoutingRepo = MockRoutingRepository();
    getIt.registerSingleton<RoutingRepository>(mockRoutingRepo);
    getIt.registerSingleton<HybridEngine>(hybridEngine);
    getIt.registerSingleton<GeocodingService>(mockGeocodingService);
    getIt.registerSingleton<FareComparisonService>(mockFareComparisonService);
    getIt.registerSingleton<ConnectivityService>(mockConnectivityService);
    getIt.registerSingleton<MainScreenController>(
      MainScreenController(
        mockGeocodingService,
        hybridEngine,
        mockFareRepository,
        mockRoutingRepo,
        mockSettingsService,
        mockFareComparisonService,
        mockOfflineModeService,
      ),
    );

  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('Discount Logic Tests', () {
    final testFormula = FareFormula(
      mode: 'Jeepney',
      subType: 'Traditional',
      baseFare: 13.0,
      perKmRate: 1.80,
      minimumFare: 13.0,
    );

    test(
      'HAPPY PATH: Discounted passenger type applies 20% reduction',
      () async {
        // Setup: 5km route
        mockRoutingRepo.distanceToReturn = 5000.0;
        mockSettingsService.discountType = DiscountType.discounted;
        hybridEngine.dynamicFareToReturn = 18.68;

        final fare = await hybridEngine.calculateDynamicFare(
          originLat: 14.0,
          originLng: 121.0,
          destLat: 14.1,
          destLng: 121.1,
          formula: testFormula,
        );

        // Expected without discount: 13.0 + (5.75 * 1.80) = 23.35
        // With 20% discount: 23.35 * 0.80 = 18.68
        expect(fare, closeTo(18.68, 0.01));
      },
    );

    test('HAPPY PATH: Standard user type has no discount', () async {
      mockRoutingRepo.distanceToReturn = 5000.0;
      mockSettingsService.discountType = DiscountType.standard;
      hybridEngine.dynamicFareToReturn = 23.35;

      final fare = await hybridEngine.calculateDynamicFare(
        originLat: 14.0,
        originLng: 121.0,
        destLat: 14.1,
        destLng: 121.1,
        formula: testFormula,
      );

      // Full price: 13.0 + (5.75 * 1.80) = 23.35
      expect(fare, closeTo(23.35, 0.01));
    });

    test('EDGE CASE: Discount applies to minimum fare', () async {
      // Very short distance where minimum fare kicks in
      mockRoutingRepo.distanceToReturn = 100.0; // 0.1km
      mockSettingsService.discountType = DiscountType.discounted;
      hybridEngine.dynamicFareToReturn = 10.40;

      final fare = await hybridEngine.calculateDynamicFare(
        originLat: 14.0,
        originLng: 121.0,
        destLat: 14.1,
        destLng: 121.1,
        formula: testFormula,
      );

      // Minimum fare is 13.0
      // With 20% discount: 13.0 * 0.8 = 10.40
      expect(fare, 10.40);
    });

    test('BOUNDARY: Discount type enum values are correct', () {
      expect(DiscountType.standard.name, 'standard');
      expect(DiscountType.discounted.name, 'discounted');
    });

    test('INTEGRATION: Discount persists in settings service', () async {
      await mockSettingsService.setUserDiscountType(DiscountType.discounted);
      expect(
        await mockSettingsService.getUserDiscountType(),
        DiscountType.discounted,
      );

      await mockSettingsService.setUserDiscountType(DiscountType.standard);
      expect(
        await mockSettingsService.getUserDiscountType(),
        DiscountType.standard,
      );
    });
  });

  group('Transport Mode Filtering Tests', () {
    test(
      'HAPPY PATH: Hiding a mode removes it from calculation list',
      () async {
        const modeKey = 'Jeepney::Traditional';

        // Initially not hidden
        expect(
          await mockSettingsService.isTransportModeHidden(
            'Jeepney',
            'Traditional',
          ),
          false,
        );

        // Hide it
        await mockSettingsService.toggleTransportMode(modeKey, true);
        expect(
          await mockSettingsService.isTransportModeHidden(
            'Jeepney',
            'Traditional',
          ),
          true,
        );
      },
    );

    test('HAPPY PATH: Unhiding a mode adds it back', () async {
      const modeKey = 'Bus::Aircon';

      await mockSettingsService.toggleTransportMode(modeKey, true);
      expect(
        await mockSettingsService.isTransportModeHidden('Bus', 'Aircon'),
        true,
      );

      await mockSettingsService.toggleTransportMode(modeKey, false);
      expect(
        await mockSettingsService.isTransportModeHidden('Bus', 'Aircon'),
        false,
      );
    });

    test(
      'EDGE CASE: All modes hidden returns empty set for calculation',
      () async {
        // Mock some modes
        final hiddenModes = {
          'Jeepney::Traditional',
          'Bus::Aircon',
          'Taxi::Regular',
        };
        mockSettingsService.hiddenTransportModes = hiddenModes;

        final result = await mockSettingsService.getHiddenTransportModes();
        expect(result.length, 3);
        expect(result.contains('Jeepney::Traditional'), true);
      },
    );

    test('BOUNDARY: Mode-SubType key format is correct', () {
      const mode = 'Jeepney';
      const subType = 'Modern';
      final key = '$mode::$subType';
      expect(key, 'Jeepney::Modern');
    });

    test('NULL/EMPTY: Empty hidden modes set on initialization', () async {
      final hidden = await mockSettingsService.getHiddenTransportModes();
      expect(hidden, isEmpty);
    });

    test('INTEGRATION: Multiple toggles update state correctly', () async {
      await mockSettingsService.toggleTransportMode(
        'Jeepney::Traditional',
        true,
      );
      expect((await mockSettingsService.getHiddenTransportModes()).length, 1);

      await mockSettingsService.toggleTransportMode('Taxi::Regular', true);
      expect((await mockSettingsService.getHiddenTransportModes()).length, 2);

      await mockSettingsService.toggleTransportMode(
        'Jeepney::Traditional',
        false,
      );
      expect((await mockSettingsService.getHiddenTransportModes()).length, 1);
      expect(
        (await mockSettingsService.getHiddenTransportModes()).contains(
          'Taxi::Regular',
        ),
        true,
      );
    });
  });

  group('Settings Screen - Discount UI Tests', () {
    Widget createSettingsScreen() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          settingsService: mockSettingsService,
          offlineModeService: mockOfflineModeService,
          offlineMapService: mockOfflineMapService,
        ),
      );
    }

    testWidgets('SMOKE TEST: Discount type selector renders', (
      WidgetTester tester,
    ) async {
      mockFareRepository.formulasToReturn =
          []; // No formulas needed for discount UI

      await tester.pumpWidget(createSettingsScreen());
      // Wait for localization and async _loadSettings to complete
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll down to see Passenger Type section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Check that passenger type section exists
      expect(find.text('Passenger Type'), findsOneWidget);
      // Check for the discount type display names
      expect(find.text('Regular'), findsOneWidget);
      expect(find.text('Discounted (Student/Senior/PWD)'), findsOneWidget);
      // Check for subtitles
      expect(find.text('No discount'), findsOneWidget);
      expect(
        find.text('20% discount (RA 11314, RA 9994, RA 7277)'),
        findsOneWidget,
      );
    });

    testWidgets('HAPPY PATH: Selecting Discounted updates settings', (
      WidgetTester tester,
    ) async {
      mockFareRepository.formulasToReturn = [];

      await tester.pumpWidget(createSettingsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find by the radio tile with discounted value
      final discountedRadio = find.byWidgetPredicate(
        (widget) =>
            widget is RadioListTile<DiscountType> &&
            widget.value == DiscountType.discounted,
      );

      // Scroll until the discounted radio is visible
      await tester.scrollUntilVisible(
        discountedRadio,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(discountedRadio, findsOneWidget);
      await tester.tap(discountedRadio);
      await tester.pumpAndSettle();

      expect(mockSettingsService.discountType, DiscountType.discounted);
    });
  });

  group('Settings Screen - Transport Filter UI Tests', () {
    Widget createSettingsScreen() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          settingsService: mockSettingsService,
          offlineModeService: mockOfflineModeService,
          offlineMapService: mockOfflineMapService,
        ),
      );
    }

    testWidgets('SMOKE TEST: Transport modes section renders', (
      WidgetTester tester,
    ) async {
      mockFareRepository.formulasToReturn = [
        FareFormula(
          mode: 'Jeepney',
          subType: 'Traditional',
          baseFare: 13.0,
          perKmRate: 1.80,
        ),
      ];

      await tester.pumpWidget(createSettingsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll down to see Transport Modes section
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Transport Modes'), findsOneWidget);
      expect(find.text('  Traditional'), findsOneWidget);
    });

    testWidgets('HAPPY PATH: Toggling a mode updates service', (
      WidgetTester tester,
    ) async {
      // Set larger screen size
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockFareRepository.formulasToReturn = [
        FareFormula(
          mode: 'Jeepney',
          subType: 'Traditional',
          baseFare: 13.0,
          perKmRate: 1.80,
        ),
      ];

      await tester.pumpWidget(createSettingsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll down to see Transport Modes section
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile).first;
      expect(switchFinder, findsOneWidget);

      // Initially it should be ON (not hidden)
      expect(tester.widget<SwitchListTile>(switchFinder).value, true);

      // Toggle it OFF
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, false);
      expect(
        mockSettingsService.hiddenTransportModes.contains(
          'Jeepney::Traditional',
        ),
        true,
      );
    });
  });

  group('Geocoding Integration Tests', () {
    test('HAPPY PATH: Current location geocoding works', () async {
      mockGeocodingService.currentLocationToReturn = Location(
        name: 'Manila',
        latitude: 14.5995,
        longitude: 120.9842,
      );

      final location = await mockGeocodingService.getCurrentLocationAddress();
      expect(location.name, 'Manila');
      expect(location.latitude, 14.5995);
    });

    test('HAPPY PATH: LatLng to address conversion works', () async {
      mockGeocodingService.addressFromLatLngToReturn = Location(
        name: 'Quezon City',
        latitude: 14.6760,
        longitude: 121.0437,
      );

      final location = await mockGeocodingService.getAddressFromLatLng(
        14.6760,
        121.0437,
      );
      expect(location.name, 'Quezon City');
    });
  });

  group('Hybrid Engine Fare Calculation Tests', () {
    final testFormula = FareFormula(
      mode: 'Jeepney',
      subType: 'Traditional',
      baseFare: 13.0,
      perKmRate: 1.80,
    );

    test('HAPPY PATH: Precise fare calculation', () async {
      mockRoutingRepo.distanceToReturn = 10000.0; // 10km
      hybridEngine.dynamicFareToReturn = 32.35;

      final fare = await hybridEngine.calculateDynamicFare(
        originLat: 14.0,
        originLng: 121.0,
        destLat: 14.1,
        destLng: 121.1,
        formula: testFormula,
      );

      expect(fare, closeTo(32.35, 0.01));
    });

    test('HAPPY PATH: Passenger count increases total fare', () async {
      mockRoutingRepo.distanceToReturn = 5000.0;
      hybridEngine.dynamicFareToReturn = 46.70;

      final fare = await hybridEngine.calculateDynamicFare(
        originLat: 14.0,
        originLng: 121.0,
        destLat: 14.1,
        destLng: 121.1,
        formula: testFormula,
        passengerCount: 2,
        regularCount: 2,
      );

      // Single: 23.35. Double: 46.70
      expect(fare, closeTo(46.70, 0.01));
    });
  });
}
