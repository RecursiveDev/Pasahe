// ... existing code ...
import 'package:flutter/material.dart';
import 'package:ph_fare_estimator/src/models/transport_mode.dart';
import 'package:ph_fare_estimator/src/models/location.dart';
import 'package:ph_fare_estimator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_estimator/src/services/routing/routing_service.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';
import 'package:ph_fare_estimator/src/core/hybrid_engine.dart';
import 'package:ph_fare_estimator/src/models/fare_formula.dart';
import 'package:ph_fare_estimator/src/models/fare_result.dart';
import 'package:ph_fare_estimator/src/models/saved_route.dart';
import 'package:ph_fare_estimator/src/repositories/fare_repository.dart';
import 'package:hive/hive.dart';

class MockRoutingService implements RoutingService {
  double? distanceToReturn;

  @override
  Future<double> getDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    if (distanceToReturn != null) return distanceToReturn!;
    return 5000.0; // Default 5km
  }
}

class MockSettingsService implements SettingsService {
  bool provincialMode = false;
  TrafficFactor trafficFactor = TrafficFactor.medium;
  bool highContrast = false;

  // Replicate static behavior instance-wise for injection
  @override
  Future<bool> getProvincialMode() async => provincialMode;

  @override
  Future<void> setProvincialMode(bool value) async {
    provincialMode = value;
  }

  @override
  Future<TrafficFactor> getTrafficFactor() async => trafficFactor;

  @override
  Future<void> setTrafficFactor(TrafficFactor factor) async {
    trafficFactor = factor;
  }

  @override
  Future<bool> getHighContrastEnabled() async => highContrast;

  @override
  Future<void> setHighContrastEnabled(bool value) async {
    highContrast = value;
  }

  @override
  Future<Locale> getLocale() async {
    return const Locale('en');
  }

  @override
  Future<void> setLocale(Locale locale) async {}
}

class MockGeocodingService implements GeocodingService {
  List<Location> locationsToReturn = [];

  @override
  Future<List<Location>> getLocations(String query) async {
    return locationsToReturn;
  }
}
// ... existing code ...

class MockHybridEngine implements HybridEngine {
  double? dynamicFareToReturn;

  MockHybridEngine();

  @override
  Future<void> initialize() async {}

  @override
  Future<double> calculateDynamicFare({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required FareFormula formula,
    bool isProvincial = false,
  }) async {
    return dynamicFareToReturn ?? 100.0;
  }

  @override
  IndicatorLevel getIndicatorLevel(String trafficFactor) {
    return IndicatorLevel.standard;
  }

  @override
  Future<double?> calculateStaticFare(
      TransportMode transportMode, String origin, String destination) async {
    return 50.0;
  }

  @override
  Future<double?> calculateFare({
    required TransportMode transportMode,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    String? originName,
    String? destinationName,
    FareFormula? formula,
    bool isProvincial = false,
  }) async {
    return dynamicFareToReturn ?? 100.0;
  }
}

class MockFareRepository implements FareRepository {
  List<FareFormula> formulasToReturn = [];
  List<SavedRoute> savedRoutesToReturn = [];

  @override
  Future<void> seedDefaults({bool force = false}) async {}

  @override
  Future<List<FareFormula>> getAllFormulas() async {
    return formulasToReturn;
  }

  @override
  Future<void> saveRoute(SavedRoute route) async {
    savedRoutesToReturn.add(route);
  }

  @override
  Future<List<SavedRoute>> getSavedRoutes() async {
    return savedRoutesToReturn;
  }

  @override
  Future<void> deleteRoute(SavedRoute route) async {
    savedRoutesToReturn.remove(route);
  }

  @override
  Future<Box<FareFormula>> openFormulaBox() async {
    throw UnimplementedError();
  }

  @override
  Future<Box<SavedRoute>> openSavedRoutesBox() async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveFormulas(List<FareFormula> formulas) async {}
}