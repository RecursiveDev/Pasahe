// ... existing code ...
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/routing/routing_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/core/hybrid_engine.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/saved_route.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/models/discount_type.dart';
import 'package:hive/hive.dart';

class MockConnectivityService implements ConnectivityService {
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  @override
  Stream<ConnectivityStatus> get connectivityStream => _controller.stream;

  @override
  ConnectivityStatus get lastKnownStatus => ConnectivityStatus.online;

  @override
  Future<ConnectivityStatus> get currentStatus async =>
      ConnectivityStatus.online;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isServiceReachable(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return true;
  }

  @override
  Future<ConnectivityStatus> checkActualConnectivity() async {
    return ConnectivityStatus.online;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class MockRoutingService implements RoutingService {
  double? distanceToReturn;

  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final distance = distanceToReturn ?? 5000.0; // Default 5km
    return RouteResult.withoutGeometry(distance: distance);
  }
}

class MockSettingsService implements SettingsService {
  bool provincialMode = false;
  TrafficFactor trafficFactor = TrafficFactor.medium;
  bool highContrast = false;
  DiscountType discountType = DiscountType.standard;

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

  @override
  Future<DiscountType> getUserDiscountType() async => discountType;

  @override
  Future<void> setUserDiscountType(DiscountType type) async {
    discountType = type;
  }

  Set<String> hiddenTransportModes = {};

  @override
  Future<Set<String>> getHiddenTransportModes() async => hiddenTransportModes;

  @override
  Future<void> toggleTransportMode(String modeSubType, bool isHidden) async {
    if (isHidden) {
      hiddenTransportModes.add(modeSubType);
    } else {
      hiddenTransportModes.remove(modeSubType);
    }
  }

  @override
  Future<bool> isTransportModeHidden(String mode, String subType) async {
    return hiddenTransportModes.contains('$mode::$subType');
  }

  Location? lastLocation;

  @override
  Future<void> saveLastLocation(Location location) async {
    lastLocation = location;
  }

  @override
  Future<Location?> getLastLocation() async {
    return lastLocation;
  }

  bool hasSetDiscount = false;

  @override
  Future<bool> hasSetDiscountType() async {
    return hasSetDiscount;
  }

  @override
  Future<Set<String>> getEnabledModes() async {
    return hiddenTransportModes;
  }

  @override
  Future<void> toggleMode(String modeId) async {
    final isCurrentlyHidden = hiddenTransportModes.contains(modeId);
    await toggleTransportMode(modeId, !isCurrentlyHidden);
  }
}

class MockGeocodingService implements GeocodingService {
  List<Location> locationsToReturn = [];
  Location? currentLocationToReturn;
  Location? addressFromLatLngToReturn;

  @override
  Future<List<Location>> getLocations(String query) async {
    return locationsToReturn;
  }

  @override
  Future<Location> getCurrentLocationAddress() async {
    return currentLocationToReturn ??
        Location(
          name: 'Mock Current Location',
          latitude: 14.5995,
          longitude: 120.9842,
        );
  }

  @override
  Future<Location> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    return addressFromLatLngToReturn ??
        Location(
          name: 'Mock Address',
          latitude: latitude,
          longitude: longitude,
        );
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
    int passengerCount = 1,
    int regularCount = 1,
    int discountedCount = 0,
  }) async {
    return dynamicFareToReturn ?? 100.0;
  }

  @override
  IndicatorLevel getIndicatorLevel(String trafficFactor) {
    return IndicatorLevel.standard;
  }

  @override
  Future<double?> calculateStaticFare(
    TransportMode transportMode,
    String origin,
    String destination, {
    int passengerCount = 1,
    int regularCount = 1,
    int discountedCount = 0,
  }) async {
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
    int passengerCount = 1,
    int regularCount = 1,
    int discountedCount = 0,
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
