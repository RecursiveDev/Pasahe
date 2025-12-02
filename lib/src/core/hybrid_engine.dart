import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../models/transport_mode.dart';
import '../models/fare_formula.dart';
import '../models/static_fare.dart';
import '../services/routing/routing_service.dart';
import '../services/settings_service.dart';
import '../models/fare_result.dart';

@lazySingleton
class HybridEngine {
  final RoutingService _routingService;
  final SettingsService _settingsService;
  Map<String, List<StaticFare>> _trainFares = {};
  List<StaticFare> _ferryFares = [];
  bool _isInitialized = false;

  HybridEngine(this._routingService, this._settingsService);

  /// Initializes the engine by loading static matrix data.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load and parse Train Matrix
      final trainJson =
          await rootBundle.loadString('assets/data/train_matrix.json');
      final trainData = json.decode(trainJson) as Map<String, dynamic>;
      _trainFares = trainData.map((key, value) {
        final list = (value as List)
            .map((item) => StaticFare.fromJson(item))
            .toList();
        return MapEntry(key, list);
      });

      // Load and parse Ferry Matrix
      final ferryJson =
          await rootBundle.loadString('assets/data/ferry_matrix.json');
      final ferryData = json.decode(ferryJson) as Map<String, dynamic>;
      if (ferryData['routes'] != null) {
        _ferryFares = (ferryData['routes'] as List)
            .map((item) => StaticFare.fromJson(item))
            .toList();
      }

      _isInitialized = true;
    } catch (e) {
      // Log error but allow engine to function for dynamic fares
      debugPrint('Error initializing HybridEngine: $e');
    }
  }

  /// Calculates the fare based on the transport mode.
  ///
  /// [transportMode]: The mode of transport (e.g., "Jeepney", "Bus", "Taxi", "Train", "Ferry").
  /// [originLat], [originLng], [destLat], [destLng]: Required for dynamic fares (Jeepney, Bus, Taxi).
  /// [originName], [destinationName]: Required for static fares (Train, Ferry).
  /// [formula]: Required for dynamic fares.
  /// [isProvincial]: Optional for dynamic fares.
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
    if (transportMode == TransportMode.train ||
        transportMode == TransportMode.ferry) {
      if (originName == null || destinationName == null) {
        throw ArgumentError(
            'Origin and Destination names are required for static fares.');
      }
      return calculateStaticFare(transportMode, originName, destinationName);
    } else {
      // Assume dynamic fare for Jeepney, Bus, Taxi, etc
      if (originLat == null ||
          originLng == null ||
          destLat == null ||
          destLng == null ||
          formula == null) {
        throw ArgumentError(
            'Coordinates and Formula are required for dynamic fares.');
      }
      return calculateDynamicFare(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        formula: formula,
        isProvincial: isProvincial,
      );
    }
  }

  /// Looks up the static fare from the loaded matrix.
  Future<double?> calculateStaticFare(
      TransportMode transportMode, String origin, String destination) async {
    if (!_isInitialized) await initialize();

    if (transportMode == TransportMode.train) {
      // Search all train lines
      for (final lineFares in _trainFares.values) {
        try {
          final fare = lineFares.firstWhere(
            (f) =>
                f.origin.toLowerCase() == origin.toLowerCase() &&
                f.destination.toLowerCase() == destination.toLowerCase(),
          );
          return fare.price;
        } catch (_) {
          // Continue to next line if not found
        }
      }
    } else if (transportMode == TransportMode.ferry) {
      try {
        final fare = _ferryFares.firstWhere(
          (f) =>
              f.origin.toLowerCase() == origin.toLowerCase() &&
              f.destination.toLowerCase() == destination.toLowerCase(),
        );
        return fare.price;
      } catch (_) {
        // Not found
      }
    }

    return null;
  }

  /// Calculates the dynamic fare based on road distance and a specific fare formula.
  Future<double> calculateDynamicFare({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required FareFormula formula,
    bool isProvincial = false,
  }) async {
    try {
      // 1. Get road distance in meters from OSRM
      final distanceInMeters = await _routingService.getDistance(
        originLat,
        originLng,
        destLat,
        destLng,
      );

      // 2. Convert to kilometers
      final distanceInKm = distanceInMeters / 1000.0;

      // 3. Apply Variance (1.15) as per PRD
      // Formula: (Road Distance x 1.15 Variance) * Rate + Base Fare
      final adjustedDistance = distanceInKm * 1.15;

      // 4. Calculate Total Fare
      double totalFare =
          formula.baseFare + (adjustedDistance * formula.perKmRate);

      // 4.1 Apply Settings-based Adjustments
      final isProvincialEnabled = await _settingsService.getProvincialMode();
      final trafficFactor = await _settingsService.getTrafficFactor();

      // Provincial Mode: +20% for Jeepneys
      if (isProvincialEnabled && formula.mode == 'Jeepney') {
        totalFare *= 1.20;
      }
      // Maintain manual override if passed, though settings take precedence for specific logic above
      else if (isProvincial) {
         totalFare *= 1.20;
      }

      // Traffic Factor: Multiplier for Taxis
      if (formula.mode == 'Taxi') {
        switch (trafficFactor) {
          case TrafficFactor.low:
            totalFare *= 0.9;
            break;
          case TrafficFactor.medium:
            totalFare *= 1.0;
            break;
          case TrafficFactor.high:
            totalFare *= 1.2;
            break;
        }
      }

      // 5. Apply Minimum Fare check if applicable
      if (formula.minimumFare != null && totalFare < formula.minimumFare!) {
        totalFare = formula.minimumFare!;
      }

      return totalFare;
    } catch (e) {
      // Re-throw the error to be handled by the UI or caller
      throw Exception('Failed to calculate dynamic fare: $e');
    }
  }

  IndicatorLevel getIndicatorLevel(String trafficFactor) {
    switch (trafficFactor) {
      case 'low':
        return IndicatorLevel.standard;
      case 'medium':
        return IndicatorLevel.peak;
      case 'high':
        return IndicatorLevel.touristTrap;
      default:
        return IndicatorLevel.standard;
    }
  }
}