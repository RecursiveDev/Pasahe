import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/presentation/controllers/main_screen_controller.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/discount_type.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/services/transport_mode_filter_service.dart';
import 'package:ph_fare_calculator/src/core/constants/region_constants.dart';

import 'helpers/mocks.dart';

class SimpleFilterService implements TransportModeFilterService {
  @override
  bool isModeValid(TransportMode mode, double lat, double lng) => true;
  
  @override
  List<TransportMode> getAvailableModes(double lat, double lng) => TransportMode.values;

  @override
  Region getRegionForLocation(double lat, double lng) => Region.nationwide;
}

class BetterMockRoutingRepository extends MockRoutingRepository {
  RouteResult? resultToReturn;

  @override
  Future<RouteResult> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    TransportMode? preferredMode,
    bool forceOffline = false,
  }) async {
    return resultToReturn ?? await super.getRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      preferredMode: preferredMode,
      forceOffline: forceOffline,
    );
  }
}

void main() {
  late MainScreenController controller;
  late MockGeocodingService mockGeocodingService;
  late MockHybridEngine mockHybridEngine;
  late MockFareRepository mockFareRepository;
  late BetterMockRoutingRepository mockRoutingRepository;
  late MockSettingsService mockSettingsService;
  late FareComparisonService fareComparisonService;
  late MockOfflineModeService mockOfflineModeService;

  setUp(() {
    mockGeocodingService = MockGeocodingService();
    mockHybridEngine = MockHybridEngine();
    mockFareRepository = MockFareRepository();
    mockRoutingRepository = BetterMockRoutingRepository();
    mockSettingsService = MockSettingsService();
    mockOfflineModeService = MockOfflineModeService();
    
    fareComparisonService = FareComparisonService(SimpleFilterService());

    controller = MainScreenController(
      mockGeocodingService,
      mockHybridEngine,
      mockFareRepository,
      mockRoutingRepository,
      mockSettingsService,
      fareComparisonService,
      mockOfflineModeService,
    );
  });

  test('BUG FIX: Accuracy level should be consistent in offline mode across all sort options', () async {
    // 1. Setup offline mode
    mockOfflineModeService.isCurrentlyOffline = true;

    final origin = Location(name: 'Origin', latitude: 14.5, longitude: 121.0);
    final destination = Location(name: 'Destination', latitude: 14.6, longitude: 121.1);
    
    final formula = FareFormula(
      mode: 'Jeepney',
      subType: 'Traditional',
      baseFare: 13.0,
      perKmRate: 1.8,
    );

    mockFareRepository.formulasToReturn = [formula];
    mockSettingsService.discountType = DiscountType.standard;
    mockSettingsService.trafficFactor = TrafficFactor.medium;
    mockSettingsService.hasSetTransportModePrefs = false;
    
    await controller.initialize();
    controller.setOriginLocation(origin);
    controller.setDestinationLocation(destination);
    
    // Wait for async route calculation to finish
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Calculate fare
    await controller.calculateFare();

    // Verify all results have Approximate accuracy because we are offline
    for (var result in controller.fareResults) {
      expect(result.accuracy, AccuracyLevel.approximate);
    }

    // 3. Switch sort criteria
    controller.setSortCriteria(SortCriteria.priceDesc);
    for (var result in controller.fareResults) {
      expect(result.accuracy, AccuracyLevel.approximate);
    }

    controller.setSortCriteria(SortCriteria.lowestOverall);
    for (var result in controller.fareResults) {
      expect(result.accuracy, AccuracyLevel.approximate);
    }
  });

  test('REGRESSION: Online mode behavior remains unchanged', () async {
    // 1. Setup online mode
    mockOfflineModeService.isCurrentlyOffline = false;
    mockRoutingRepository.resultToReturn = RouteResult(
      distance: 1000,
      duration: 600,
      geometry: [],
      source: RouteSource.osrm,
      accuracy: AccuracyLevel.precise,
    );

    final origin = Location(name: 'Origin', latitude: 14.5, longitude: 121.0);
    final destination = Location(name: 'Destination', latitude: 14.6, longitude: 121.1);
    
    final formula = FareFormula(
      mode: 'Jeepney',
      subType: 'Traditional',
      baseFare: 13.0,
      perKmRate: 1.8,
    );

    mockFareRepository.formulasToReturn = [formula];
    mockSettingsService.discountType = DiscountType.standard;
    mockSettingsService.trafficFactor = TrafficFactor.medium;
    mockSettingsService.hasSetTransportModePrefs = false;
    
    await controller.initialize();
    controller.setOriginLocation(origin);
    controller.setDestinationLocation(destination);
    
    // Wait for async route calculation to finish
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Calculate fare
    await controller.calculateFare();

    // Verify results show Precise accuracy (default for OSRM mock)
    for (var result in controller.fareResults) {
      expect(result.accuracy, AccuracyLevel.precise);
    }
  });

  test('REGRESSION: Toggling offline mode without recalculating updates existing results', () async {
    // 1. Start online
    mockOfflineModeService.isCurrentlyOffline = false;
    mockRoutingRepository.resultToReturn = RouteResult(
      distance: 1000,
      duration: 600,
      geometry: [],
      source: RouteSource.osrm,
      accuracy: AccuracyLevel.precise,
    );

    final origin = Location(name: 'Origin', latitude: 14.5, longitude: 121.0);
    final destination = Location(name: 'Destination', latitude: 14.6, longitude: 121.1);
    
    final formula = FareFormula(
      mode: 'Jeepney',
      subType: 'Traditional',
      baseFare: 13.0,
      perKmRate: 1.8,
    );

    mockFareRepository.formulasToReturn = [formula];
    mockSettingsService.discountType = DiscountType.standard;
    mockSettingsService.trafficFactor = TrafficFactor.medium;
    mockSettingsService.hasSetTransportModePrefs = false;
    
    await controller.initialize();
    controller.setOriginLocation(origin);
    controller.setDestinationLocation(destination);
    await Future.delayed(const Duration(milliseconds: 100));
    await controller.calculateFare();

    // Verify initial online results
    for (var result in controller.fareResults) {
      expect(result.accuracy, AccuracyLevel.precise);
    }

    // 2. Toggle offline mode
    mockOfflineModeService.isCurrentlyOffline = true;

    // Verify that results were updated to Approximate via the listener
    for (var result in controller.fareResults) {
      expect(result.accuracy, AccuracyLevel.approximate);
    }
  });
}
