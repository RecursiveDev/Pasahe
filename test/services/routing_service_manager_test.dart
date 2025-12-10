import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/routing/haversine_routing_service.dart';
import 'package:ph_fare_calculator/src/services/routing/osrm_routing_service.dart';
import 'package:ph_fare_calculator/src/services/routing/route_cache_service.dart';
import 'package:ph_fare_calculator/src/services/routing/routing_service_manager.dart';
import 'package:ph_fare_calculator/src/core/errors/failures.dart';

// Mock classes for testing
class MockOsrmRoutingService implements OsrmRoutingService {
  RouteResult? mockResult;
  Object? mockError;
  int callCount = 0;

  @override
  String get baseUrl => 'http://mock.osrm.org';

  @override
  Duration get timeout => const Duration(seconds: 10);

  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    callCount++;
    if (mockError != null) {
      throw mockError!;
    }
    return mockResult ??
        RouteResult(
          distance: 5000,
          duration: 600,
          geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
          source: RouteSource.osrm,
        );
  }

  @override
  void dispose() {}
}

class MockHaversineRoutingService implements HaversineRoutingService {
  int callCount = 0;

  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    callCount++;
    return RouteResult(
      distance: 4500,
      duration: 540,
      geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
      source: RouteSource.haversine,
    );
  }
}

class MockRouteCacheService implements RouteCacheService {
  final Map<String, RouteResult> _cache = {};
  int getCacheCallCount = 0;
  int setCacheCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  String generateCacheKey(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    return '$originLat,$originLng->$destLat,$destLng';
  }

  @override
  Future<RouteResult?> getCachedRoute(String cacheKey) async {
    getCacheCallCount++;
    return _cache[cacheKey]?.asFromCache();
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
    setCacheCallCount++;
    final now = DateTime.now();
    _cache[cacheKey] = route.withCacheMetadata(
      cachedAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
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
    _cache.remove(cacheKey);
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  @override
  int get cacheSize => _cache.length;

  @override
  List<String> get cachedKeys => _cache.keys.toList();

  @override
  Future<void> dispose() async {}

  // Test helper
  void addToCache(String key, RouteResult route) {
    _cache[key] = route;
  }
}

class MockConnectivityService implements ConnectivityService {
  ConnectivityStatus mockStatus = ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get connectivityStream => Stream.value(mockStatus);

  @override
  Future<ConnectivityStatus> get currentStatus async => mockStatus;

  @override
  ConnectivityStatus get lastKnownStatus => mockStatus;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isServiceReachable(String url, {Duration? timeout}) async =>
      mockStatus.isOnline;

  @override
  Future<ConnectivityStatus> checkActualConnectivity() async => mockStatus;

  @override
  Future<void> dispose() async {}
}

void main() {
  group('RoutingServiceManager', () {
    late MockOsrmRoutingService mockOsrm;
    late MockHaversineRoutingService mockHaversine;
    late MockRouteCacheService mockCache;
    late MockConnectivityService mockConnectivity;
    late RoutingServiceManager manager;

    const originLat = 14.5995;
    const originLng = 120.9842;
    const destLat = 14.6091;
    const destLng = 121.0223;

    setUp(() {
      mockOsrm = MockOsrmRoutingService();
      mockHaversine = MockHaversineRoutingService();
      mockCache = MockRouteCacheService();
      mockConnectivity = MockConnectivityService();

      manager = RoutingServiceManager(
        mockOsrm,
        mockHaversine,
        mockCache,
        mockConnectivity,
      );
    });

    group('getRoute with preferCache=true (default)', () {
      test('should return cached route if available', () async {
        // Setup: Add a cached route
        final cachedRoute = RouteResult(
          distance: 6000,
          duration: 720,
          geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
          source: RouteSource.cache,
        );
        final cacheKey = mockCache.generateCacheKey(
          originLat,
          originLng,
          destLat,
          destLng,
        );
        mockCache.addToCache(cacheKey, cachedRoute);

        // Act
        final result = await manager.getRoute(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        // Assert
        expect(result.source, RouteSource.cache);
        expect(result.distance, 6000);
        expect(mockOsrm.callCount, 0); // OSRM should not be called
        expect(mockHaversine.callCount, 0);
      });

      test('should try OSRM when cache misses and online', () async {
        // Setup
        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockResult = RouteResult(
          distance: 5500,
          duration: 660,
          geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
          source: RouteSource.osrm,
        );

        // Act
        final result = await manager.getRoute(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        // Assert
        expect(result.source, RouteSource.osrm);
        expect(result.distance, 5500);
        expect(mockOsrm.callCount, 1);
        expect(mockCache.setCacheCallCount, 1); // Should cache the result
      });

      test(
        'should fall back to Haversine when OSRM fails and no cache',
        () async {
          // Setup
          mockConnectivity.mockStatus = ConnectivityStatus.online;
          mockOsrm.mockError = const NetworkFailure('Network error');

          // Act
          final result = await manager.getRoute(
            originLat,
            originLng,
            destLat,
            destLng,
          );

          // Assert
          expect(result.source, RouteSource.haversine);
          expect(mockOsrm.callCount, 1);
          expect(mockHaversine.callCount, 1);
        },
      );

      test('should skip OSRM and use Haversine when offline', () async {
        // Setup
        mockConnectivity.mockStatus = ConnectivityStatus.offline;

        // Act
        final result = await manager.getRoute(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        // Assert
        expect(result.source, RouteSource.haversine);
        expect(mockOsrm.callCount, 0); // Should not call OSRM when offline
        expect(mockHaversine.callCount, 1);
      });
    });

    group('getRouteFresh', () {
      test('should always try OSRM first regardless of cache', () async {
        // Setup
        final cachedRoute = RouteResult(
          distance: 6000,
          duration: 720,
          geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
          source: RouteSource.cache,
        );
        final cacheKey = mockCache.generateCacheKey(
          originLat,
          originLng,
          destLat,
          destLng,
        );
        mockCache.addToCache(cacheKey, cachedRoute);

        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockResult = RouteResult(
          distance: 5500,
          duration: 660,
          geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
          source: RouteSource.osrm,
        );

        // Act
        final result = await manager.getRouteFresh(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        // Assert
        expect(result.source, RouteSource.osrm);
        expect(mockOsrm.callCount, 1);
      });
    });

    group('error handling', () {
      test('should handle NetworkFailure gracefully', () async {
        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockError = const NetworkFailure('Connection timeout');

        final result = await manager.getRoute(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        expect(result.source, RouteSource.haversine);
      });

      test('should handle ServerFailure gracefully', () async {
        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockError = const ServerFailure('OSRM server error');

        final result = await manager.getRoute(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        expect(result.source, RouteSource.haversine);
      });

      test('should handle unexpected errors gracefully', () async {
        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockError = Exception('Unexpected error');

        final result = await manager.getRoute(
          originLat,
          originLng,
          destLat,
          destLng,
        );

        expect(result.source, RouteSource.haversine);
      });
    });

    group('caching', () {
      test('should cache successful OSRM results', () async {
        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockResult = RouteResult(
          distance: 5500,
          duration: 660,
          geometry: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
          source: RouteSource.osrm,
        );

        await manager.getRoute(originLat, originLng, destLat, destLng);

        expect(mockCache.setCacheCallCount, 1);
      });

      test('should not cache failed OSRM attempts', () async {
        mockConnectivity.mockStatus = ConnectivityStatus.online;
        mockOsrm.mockError = const NetworkFailure('Error');

        await manager.getRoute(originLat, originLng, destLat, destLng);

        expect(mockCache.setCacheCallCount, 0);
      });

      test('clearCache should clear the cache service', () async {
        await manager.clearCache();
        expect(mockCache.cacheSize, 0);
      });
    });
  });
}
