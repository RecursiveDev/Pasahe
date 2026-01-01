import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as fmtc;
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:ph_fare_calculator/src/core/hybrid_engine.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/discount_type.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/models/map_region.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/models/saved_route.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_cache_service.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:ph_fare_calculator/src/services/routing/haversine_routing_service.dart';
import 'package:ph_fare_calculator/src/services/routing/osrm_routing_service.dart';
import 'package:ph_fare_calculator/src/services/routing/route_cache_service.dart';
import 'package:ph_fare_calculator/src/services/routing/routing_service.dart';
import 'package:ph_fare_calculator/src/services/routing/train_ferry_graph_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';

class MockConnectivityService implements ConnectivityService {
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get connectivityStream => _controller.stream;

  @override
  ConnectivityStatus get lastKnownStatus => _currentStatus;

  @override
  bool get isWifi => _currentStatus == ConnectivityStatus.online;

  @override
  Future<ConnectivityStatus> get currentStatus async => _currentStatus;

  @override
  Future<void> initialize() async {}

  void setConnectivityStatus(ConnectivityStatus status) {
    _currentStatus = status;
    _controller.add(status);
  }

  @override
  Future<bool> isServiceReachable(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return true;
  }

  @override
  Future<ConnectivityStatus> checkActualConnectivity() async {
    return _currentStatus;
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

class MockRoutingRepository implements RoutingRepository {
  double? distanceToReturn;

  @override
  Future<RouteResult> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    TransportMode? preferredMode,
    bool forceOffline = false,
  }) async {
    final distance = distanceToReturn ?? 5000.0;
    return RouteResult.withoutGeometry(distance: distance);
  }
}

class MockSettingsService implements SettingsService {
  bool provincialMode = false;
  TrafficFactor trafficFactor = TrafficFactor.medium;
  String themeMode = 'system';
  DiscountType discountType = DiscountType.standard;
  bool offlineModeEnabled = false;
  bool autoCacheEnabled = true;
  bool autoCacheWifiOnly = true;
  bool offlineModeMigrated = false;

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
  Future<String> getThemeMode() async => themeMode;

  @override
  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
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

  bool hasSetTransportModePrefs = true;

  @override
  Future<bool> hasSetTransportModePreferences() async {
    return hasSetTransportModePrefs;
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

  @override
  Future<bool> getOfflineModeEnabled() async => offlineModeEnabled;

  @override
  Future<void> setOfflineModeEnabled(bool value) async {
    offlineModeEnabled = value;
  }

  @override
  Future<bool> getAutoCacheEnabled() async => autoCacheEnabled;

  @override
  Future<void> setAutoCacheEnabled(bool value) async {
    autoCacheEnabled = value;
  }

  @override
  Future<bool> getAutoCacheWifiOnly() async => autoCacheWifiOnly;

  @override
  Future<void> setAutoCacheWifiOnly(bool value) async {
    autoCacheWifiOnly = value;
  }

  @override
  Future<bool> hasMigratedToOfflineMode() async => offlineModeMigrated;

  @override
  Future<void> setMigratedToOfflineMode(bool value) async {
    offlineModeMigrated = value;
  }
}

class MockOfflineMapService implements OfflineMapService {
  List<MapRegion> _downloadedRegions = [];

  @override
  Future<void> initialize() async {}

  void setDownloadedRegions(List<MapRegion> regions) {
    _downloadedRegions = regions;
  }

  @override
  List<MapRegion> get allRegions => [];

  @override
  Future<List<MapRegion>> getIslandGroups() async => [];

  @override
  Future<List<MapRegion>> getIslandsForGroup(String parentId) async => [];

  @override
  MapRegion? getRegionById(String id) => null;

  @override
  fmtc.FMTCStore get store => throw UnimplementedError();

  @override
  Stream<RegionDownloadProgress> downloadRegion(MapRegion region) async* {}

  @override
  Future<void> downloadIslandGroup(String groupId) async {}

  @override
  Future<DownloadStatus> getGroupDownloadStatus(String groupId) async =>
      DownloadStatus.notDownloaded;

  @override
  Future<void> pauseDownload() async {}

  @override
  Stream<RegionDownloadProgress> resumeDownload(MapRegion region) async* {}

  @override
  Future<void> cancelDownload() async {}

  @override
  Future<void> deleteRegion(MapRegion region) async {}

  @override
  Future<void> deleteIslandGroup(String groupId) async {}

  @override
  Future<List<MapRegion>> getDownloadedRegions() async => _downloadedRegions;

  @override
  Future<StorageInfo> getStorageUsage() async {
    return const StorageInfo(
      appStorageBytes: 1024 * 1024 * 5,
      mapCacheBytes: 1024 * 1024 * 5,
      availableBytes: 1024 * 1024 * 1024,
      totalBytes: 1024 * 1024 * 1024 * 10,
    );
  }

  @override
  Future<void> clearAllTiles() async {}

  @override
  TileLayer getCachedTileLayer() => throw UnimplementedError();

  @override
  TileLayer getThemedCachedTileLayer({
    required bool isDarkMode,
    bool allowDownloads = true,
  }) => throw UnimplementedError();

  @override
  bool isPointCached(LatLng point) => false;

  @override
  int estimateTileCount(MapRegion region) => 0;

  @override
  Future<void> dispose() async {}

  @override
  bool get isDownloading => false;

  @override
  Stream<RegionDownloadProgress> get progressStream => const Stream.empty();
}

class MockOfflineModeService extends ChangeNotifier
    implements OfflineModeService {
  bool _isCurrentlyOffline = false;

  @override
  ConnectivityStatus get connectivityStatus => ConnectivityStatus.online;

  @override
  bool get offlineModeEnabled => false;

  @override
  bool get autoCacheEnabled => true;

  @override
  bool get autoCacheWifiOnly => true;

  @override
  List<String> get downloadedRegionIds => [];

  @override
  bool get isAutoCaching => false;

  @override
  bool get isCurrentlyOffline => _isCurrentlyOffline;

  set isCurrentlyOffline(bool value) {
    _isCurrentlyOffline = value;
    notifyListeners();
  }

  @override
  AccuracyLevel get currentAccuracyLevel => AccuracyLevel.precise;

  @override
  Future<void> initialize() async {}

  @override
  void _handleConnectivityChange(ConnectivityStatus status) {}

  @override
  Future<void> setOfflineModeEnabled(bool enabled) async {}

  @override
  Future<void> setAutoCacheEnabled(bool enabled) async {}

  @override
  Future<void> setAutoCacheWifiOnly(bool wifiOnly) async {}

  @override
  Future<void> refreshDownloadedRegions() async {}

  @override
  bool get shouldAllowDownloads => true;
}

class MockGeocodingCacheService implements GeocodingCacheService {
  Map<String, List<Location>> cache = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Location>?> getCachedResults(String key) async {
    return cache[key];
  }

  @override
  Future<void> cacheResults(String key, List<Location> locations) async {
    cache[key] = locations;
  }

  @override
  Future<void> clearCache() async {
    cache.clear();
  }
}

class MockRouteCacheService implements RouteCacheService {
  final Map<String, RouteResult> cache = {};
  final List<String> cachingKeys = [];
  bool shouldReturnCached = false;
  bool shouldFail = false;

  @override
  Future<void> initialize() async {}

  @override
  String generateCacheKey(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    final origin =
        '${originLat.toStringAsFixed(5)},${originLng.toStringAsFixed(5)}';
    final dest = '${destLat.toStringAsFixed(5)},${destLng.toStringAsFixed(5)}';
    final rawKey = '$origin->$dest';
    return rawKey.hashCode.toRadixString(16);
  }

  @override
  Future<RouteResult?> getCachedRoute(String cacheKey) async {
    if (shouldReturnCached && cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }
    return null;
  }

  @override
  Future<RouteResult?> getCachedRouteByCoords(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final key = generateCacheKey(originLat, originLng, destLat, destLng);
    return getCachedRoute(key);
  }

  @override
  Future<void> cacheRoute(String cacheKey, RouteResult route) async {
    cachingKeys.add(cacheKey);
    cache[cacheKey] = route;
  }

  @override
  Future<void> cacheRouteByCoords(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
    RouteResult route,
  ) async {
    final key = generateCacheKey(originLat, originLng, destLat, destLng);
    await cacheRoute(key, route);
  }

  @override
  Future<void> removeCachedRoute(String cacheKey) async {
    cache.remove(cacheKey);
  }

  @override
  Future<void> clearCache() async {
    cache.clear();
    cachingKeys.clear();
  }

  @override
  int get cacheSize => cache.length;

  @override
  List<String> get cachedKeys => cache.keys.cast<String>().toList();

  @override
  Future<void> dispose() async {}
}

class MockTrainFerryGraphService implements TrainFerryGraphService {
  bool shouldFindPath = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<StationNode>> findNearbyStations(
    double lat,
    double lng,
    TransportMode mode, {
    double maxDistanceMeters = 5000,
  }) async {
    if (shouldFindPath) {
      return [
        StationNode(
          id: 'mock_station',
          name: 'Mock Station',
          latitude: lat,
          longitude: lng,
          lineId: 'mock_line',
          transportMode: mode,
        ),
      ];
    }
    return [];
  }

  @override
  Future<RouteResult?> findPath(
    String originNodeId,
    String destNodeId,
    TransportMode mode,
  ) async {
    if (shouldFindPath) {
      return RouteResult.withoutGeometry(
        distance: 10000.0,
        source: RouteSource.graph,
      );
    }
    return null;
  }
}

class MockHaversineRoutingService implements HaversineRoutingService {
  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    return RouteResult.withoutGeometry(
      distance: 6000.0,
      source: RouteSource.haversine,
    );
  }
}

class MockOsrmRoutingService implements OsrmRoutingService {
  bool shouldFail = false;

  @override
  final String baseUrl = 'http://mock-osrm';

  @override
  final Duration timeout = const Duration(seconds: 10);

  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    if (shouldFail) {
      throw Exception('OSRM request failed');
    }
    return RouteResult.withoutGeometry(
      distance: 5000.0,
      source: RouteSource.osrm,
    );
  }

  @override
  void dispose() {}
}

class MockGeocodingService implements GeocodingService {
  bool shouldFail = false;
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
    if (shouldFail) {
      throw Exception('Geocoding failed');
    }
    return addressFromLatLngToReturn ??
        Location(
          name: 'Mock Address',
          latitude: latitude,
          longitude: longitude,
        );
  }
}

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
