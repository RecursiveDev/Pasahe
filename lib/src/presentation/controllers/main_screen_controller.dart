import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../core/errors/failures.dart';
import '../../core/hybrid_engine.dart';
import '../../models/discount_type.dart';
import '../../models/fare_formula.dart';
import '../../models/fare_result.dart';
import '../../models/location.dart';
import '../../models/route_result.dart';
import '../../models/saved_route.dart';
import '../../repositories/fare_repository.dart';
import '../../services/fare_comparison_service.dart';
import '../../services/geocoding/geocoding_service.dart';
import '../../services/routing/routing_service.dart';
import '../../services/settings_service.dart';

/// State controller for MainScreen following the ChangeNotifier pattern.
/// Extracts all state and business logic from the MainScreen widget.
class MainScreenController extends ChangeNotifier {
  // Dependencies
  final GeocodingService _geocodingService;
  final HybridEngine _hybridEngine;
  final FareRepository _fareRepository;
  final RoutingService _routingService;
  final SettingsService _settingsService;
  final FareComparisonService _fareComparisonService;

  // Location state
  Location? _originLocation;
  Location? _destinationLocation;
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  // Route state
  List<LatLng> _routePoints = [];
  RouteResult? _routeResult;

  // Data state
  List<FareFormula> _availableFormulas = [];
  bool _isLoading = true;
  bool _isCalculating = false;
  bool _isLoadingLocation = false;

  // Passenger state
  int _passengerCount = 1;
  int _regularPassengers = 1;
  int _discountedPassengers = 0;

  // Results state
  List<FareResult> _fareResults = [];
  SortCriteria _sortCriteria = SortCriteria.priceAsc;
  String? _errorMessage;

  // Debounce timers
  Timer? _originDebounceTimer;
  Timer? _destinationDebounceTimer;

  // Constructor with dependency injection
  MainScreenController({
    GeocodingService? geocodingService,
    HybridEngine? hybridEngine,
    FareRepository? fareRepository,
    RoutingService? routingService,
    SettingsService? settingsService,
    FareComparisonService? fareComparisonService,
  }) : _geocodingService = geocodingService ?? getIt<GeocodingService>(),
       _hybridEngine = hybridEngine ?? getIt<HybridEngine>(),
       _fareRepository = fareRepository ?? getIt<FareRepository>(),
       _routingService = routingService ?? getIt<RoutingService>(),
       _settingsService = settingsService ?? getIt<SettingsService>(),
       _fareComparisonService =
           fareComparisonService ?? getIt<FareComparisonService>();

  // Getters
  Location? get originLocation => _originLocation;
  Location? get destinationLocation => _destinationLocation;
  LatLng? get originLatLng => _originLatLng;
  LatLng? get destinationLatLng => _destinationLatLng;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  RouteResult? get routeResult => _routeResult;
  RouteSource? get routeSource => _routeResult?.source;
  List<FareFormula> get availableFormulas =>
      List.unmodifiable(_availableFormulas);
  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  bool get isLoadingLocation => _isLoadingLocation;
  int get passengerCount => _passengerCount;
  int get regularPassengers => _regularPassengers;
  int get discountedPassengers => _discountedPassengers;
  int get totalPassengers => _regularPassengers + _discountedPassengers;
  List<FareResult> get fareResults => List.unmodifiable(_fareResults);
  SortCriteria get sortCriteria => _sortCriteria;
  String? get errorMessage => _errorMessage;
  bool get canCalculate =>
      !_isLoading &&
      !_isCalculating &&
      _originLocation != null &&
      _destinationLocation != null;

  /// Returns true if the current route is road-based (OSRM or cached).
  bool get isRoadBasedRoute => _routeResult?.source.isRoadBased ?? false;

  /// Returns the route distance in meters.
  double? get routeDistance => _routeResult?.distance;

  /// Returns the route duration in seconds.
  double? get routeDuration => _routeResult?.duration;

  /// Initialize data from repositories and settings
  Future<void> initialize() async {
    final formulas = await _fareRepository.getAllFormulas();
    final lastLocation = await _settingsService.getLastLocation();
    final userDiscountType = await _settingsService.getUserDiscountType();

    _availableFormulas = formulas;
    _isLoading = false;

    if (lastLocation != null) {
      _originLocation = lastLocation;
      _originLatLng = LatLng(lastLocation.latitude, lastLocation.longitude);
    }

    // Set initial passenger type based on user preference
    if (userDiscountType.name == 'discounted' && _passengerCount == 1) {
      _regularPassengers = 0;
      _discountedPassengers = 1;
    } else {
      _regularPassengers = 1;
      _discountedPassengers = 0;
    }

    notifyListeners();
  }

  /// Check if user has set discount type before
  Future<bool> hasSetDiscountType() async {
    return _settingsService.hasSetDiscountType();
  }

  /// Set user discount type preference and update local passenger state.
  Future<void> setUserDiscountType(DiscountType discountType) async {
    await _settingsService.setUserDiscountType(discountType);

    // Update local passenger counts based on the selected discount type
    // Assuming a total of 1 passenger when first setting the preference
    if (discountType == DiscountType.discounted) {
      _regularPassengers = 0;
      _discountedPassengers = 1;
    } else {
      _regularPassengers = 1;
      _discountedPassengers = 0;
    }
    _passengerCount = _regularPassengers + _discountedPassengers;

    notifyListeners();
  }

  /// Search locations with debounce for autocomplete
  Future<List<Location>> searchLocations(String query, bool isOrigin) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final debounceTimer = isOrigin
        ? _originDebounceTimer
        : _destinationDebounceTimer;
    debounceTimer?.cancel();

    final completer = Completer<List<Location>>();

    final newTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final locations = await _geocodingService.getLocations(query);
        if (!completer.isCompleted) {
          completer.complete(locations);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      }
    });

    if (isOrigin) {
      _originDebounceTimer = newTimer;
    } else {
      _destinationDebounceTimer = newTimer;
    }

    return completer.future;
  }

  /// Set origin location
  void setOriginLocation(Location location) {
    _originLocation = location;
    _originLatLng = LatLng(location.latitude, location.longitude);
    _resetResult();
    notifyListeners();

    if (_originLocation != null && _destinationLocation != null) {
      calculateRoute();
    }
  }

  /// Set destination location
  void setDestinationLocation(Location location) {
    _destinationLocation = location;
    _destinationLatLng = LatLng(location.latitude, location.longitude);
    _resetResult();
    notifyListeners();

    if (_originLocation != null && _destinationLocation != null) {
      calculateRoute();
    }
  }

  /// Swap origin and destination
  void swapLocations() {
    if (_originLocation == null && _destinationLocation == null) return;

    final tempLocation = _originLocation;
    final tempLatLng = _originLatLng;

    _originLocation = _destinationLocation;
    _originLatLng = _destinationLatLng;

    _destinationLocation = tempLocation;
    _destinationLatLng = tempLatLng;

    _resetResult();
    notifyListeners();

    if (_originLocation != null && _destinationLocation != null) {
      calculateRoute();
    }
  }

  /// Update passengers
  void updatePassengers(int regular, int discounted) {
    _regularPassengers = regular;
    _discountedPassengers = discounted;
    _passengerCount = regular + discounted;
    notifyListeners();

    if (_originLocation != null && _destinationLocation != null) {
      calculateFare();
    }
  }

  /// Update sort criteria
  void setSortCriteria(SortCriteria criteria) {
    _sortCriteria = criteria;
    if (_fareResults.isNotEmpty) {
      _fareResults = _fareComparisonService.sortFares(_fareResults, criteria);
      _updateRecommendedFlag();
    }
    notifyListeners();
  }

  /// Calculate route from routing service
  Future<void> calculateRoute() async {
    if (_originLocation == null || _destinationLocation == null) {
      return;
    }

    try {
      debugPrint('MainScreenController: Calculating route...');

      final result = await _routingService.getRoute(
        _originLocation!.latitude,
        _originLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      _routeResult = result;
      _routePoints = result.geometry;

      debugPrint(
        'MainScreenController: Route calculated - '
        '${result.distance.toStringAsFixed(0)}m, '
        '${result.geometry.length} points, '
        'source: ${result.source.description}',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('MainScreenController: Error calculating route: $e');
      // Clear route on error
      _routeResult = null;
      _routePoints = [];
      notifyListeners();
    }
  }

  /// Calculate fare for all available transport modes
  Future<void> calculateFare() async {
    _errorMessage = null;
    _fareResults = [];
    _isCalculating = true;
    notifyListeners();

    try {
      if (_originLocation != null) {
        await _settingsService.saveLastLocation(_originLocation!);
      }

      final List<FareResult> results = [];
      final trafficFactor = await _settingsService.getTrafficFactor();
      final hiddenModes = await _settingsService.getHiddenTransportModes();

      final visibleFormulas = _availableFormulas.where((formula) {
        final modeSubTypeKey = '${formula.mode}::${formula.subType}';
        return !hiddenModes.contains(modeSubTypeKey);
      }).toList();

      if (visibleFormulas.isEmpty) {
        _errorMessage =
            'No transport modes enabled. Please enable at least one mode in Settings.';
        _isCalculating = false;
        notifyListeners();
        return;
      }

      for (final formula in visibleFormulas) {
        if (formula.baseFare == 0.0 && formula.perKmRate == 0.0) {
          debugPrint(
            'Skipping invalid formula for ${formula.mode} (${formula.subType})',
          );
          continue;
        }

        final fare = await _hybridEngine.calculateDynamicFare(
          originLat: _originLocation!.latitude,
          originLng: _originLocation!.longitude,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
          formula: formula,
          passengerCount: _passengerCount,
          regularCount: _regularPassengers,
          discountedCount: _discountedPassengers,
        );

        final indicator = formula.mode == 'Taxi'
            ? _hybridEngine.getIndicatorLevel(trafficFactor.name)
            : IndicatorLevel.standard;

        results.add(
          FareResult(
            transportMode: '${formula.mode} (${formula.subType})',
            fare: fare,
            indicatorLevel: indicator,
            isRecommended: false,
            passengerCount: _passengerCount,
            totalFare: fare,
          ),
        );
      }

      final sortedResults = _fareComparisonService.sortFares(
        results,
        _sortCriteria,
      );

      if (sortedResults.isNotEmpty) {
        sortedResults[0] = FareResult(
          transportMode: sortedResults[0].transportMode,
          fare: sortedResults[0].fare,
          indicatorLevel: sortedResults[0].indicatorLevel,
          isRecommended: true,
          passengerCount: sortedResults[0].passengerCount,
          totalFare: sortedResults[0].totalFare,
        );
      }

      _fareResults = sortedResults;
      _isCalculating = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating fare: $e');
      String msg =
          'Could not calculate fare. Please check your route and try again.';
      if (e is Failure) {
        msg = e.message;
      }

      _fareResults = [];
      _errorMessage = msg;
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// Save current route
  Future<void> saveRoute() async {
    if (_originLocation == null ||
        _destinationLocation == null ||
        _fareResults.isEmpty) {
      return;
    }

    final route = SavedRoute(
      origin: _originLocation!.name,
      destination: _destinationLocation!.name,
      fareResults: _fareResults,
      timestamp: DateTime.now(),
    );

    await _fareRepository.saveRoute(route);
  }

  /// Get current location and reverse geocode it
  Future<Location> getCurrentLocationAddress() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = await _geocodingService.getCurrentLocationAddress();
      _isLoadingLocation = false;
      notifyListeners();
      return location;
    } catch (e) {
      _isLoadingLocation = false;
      String errorMsg = 'Failed to get current location.';
      if (e is Failure) {
        errorMsg = e.message;
      }
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  /// Get address from coordinates (for map picker)
  Future<Location> getAddressFromLatLng(double lat, double lng) async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = await _geocodingService.getAddressFromLatLng(lat, lng);
      _isLoadingLocation = false;
      notifyListeners();
      return location;
    } catch (e) {
      _isLoadingLocation = false;
      String errorMsg = 'Failed to get address for selected location.';
      if (e is Failure) {
        errorMsg = e.message;
      }
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset results and route
  void _resetResult() {
    if (_fareResults.isNotEmpty ||
        _errorMessage != null ||
        _routePoints.isNotEmpty ||
        _routeResult != null) {
      _fareResults = [];
      _errorMessage = null;
      _routePoints = [];
      _routeResult = null;
    }
  }

  /// Update recommended flag on results
  void _updateRecommendedFlag() {
    if (_fareResults.isEmpty) return;

    _fareResults = _fareResults.map((result) {
      return FareResult(
        transportMode: result.transportMode,
        fare: result.fare,
        indicatorLevel: result.indicatorLevel,
        isRecommended: false,
        passengerCount: result.passengerCount,
        totalFare: result.totalFare,
      );
    }).toList();

    _fareResults[0] = FareResult(
      transportMode: _fareResults[0].transportMode,
      fare: _fareResults[0].fare,
      indicatorLevel: _fareResults[0].indicatorLevel,
      isRecommended: true,
      passengerCount: _fareResults[0].passengerCount,
      totalFare: _fareResults[0].totalFare,
    );
  }

  @override
  void dispose() {
    _originDebounceTimer?.cancel();
    _destinationDebounceTimer?.cancel();
    super.dispose();
  }
}
