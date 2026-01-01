import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';

import '../helpers/mocks.dart';

void main() {
  late MockConnectivityService mockConnectivityService;
  late MockRouteCacheService mockRouteCacheService;
  late MockTrainFerryGraphService mockTrainFerryGraphService;
  late MockHaversineRoutingService mockHaversineRoutingService;
  late MockOsrmRoutingService mockOsrmRoutingService;
  late MockOfflineModeService mockOfflineModeService;
  late RoutingRepository repository;

  setUp(() {
    mockConnectivityService = MockConnectivityService();
    mockRouteCacheService = MockRouteCacheService();
    mockTrainFerryGraphService = MockTrainFerryGraphService();
    mockHaversineRoutingService = MockHaversineRoutingService();
    mockOsrmRoutingService = MockOsrmRoutingService();
    mockOfflineModeService = MockOfflineModeService();
    repository = RoutingRepository(
      mockOsrmRoutingService,
      mockRouteCacheService,
      mockTrainFerryGraphService,
      mockHaversineRoutingService,
      mockConnectivityService,
      mockOfflineModeService,
    );
  });

  group('RoutingRepository - OSRM Fallback', () {
    test('should return OSRM result when online', () async {
      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.distance, equals(5000.0));
      expect(result.source, RouteSource.osrm);
    });

    test('should fall back to cache when OSRM fails', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockRouteCacheService.shouldReturnCached = true;

      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      mockRouteCacheService.cache[cacheKey] = RouteResult.withoutGeometry(
        distance: 4000.0,
        source: RouteSource.cache,
      );

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.distance, equals(4000.0));
      expect(result.source, RouteSource.cache);
    });

    test(
      'should fall back to Haversine when both OSRM and cache fail',
      () async {
        mockOsrmRoutingService.shouldFail = true;
        mockRouteCacheService.shouldReturnCached = false;

        final result = await repository.getRoute(
          originLat: 14.5995,
          originLng: 120.9842,
          destLat: 14.6561,
          destLng: 121.0247,
        );

        expect(result.distance, equals(6000.0));
        expect(result.source, RouteSource.haversine);
      },
    );

    test('should use forceOffline to skip OSRM', () async {
      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
        forceOffline: true,
      );

      // Should not use OSRM when forceOffline is true
      expect(result.source, isNot(RouteSource.osrm));
    });
  });

  group('RoutingRepository - Cache Integration', () {
    test('should cache OSRM results', () async {
      await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(mockRouteCacheService.cachingKeys.length, equals(1));
    });

    test('should retrieve cached routes for same coordinates', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockRouteCacheService.shouldReturnCached = true;
      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      mockRouteCacheService.cache[cacheKey] = RouteResult.withoutGeometry(
        distance: 3000.0,
        source: RouteSource.cache,
      );

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.distance, equals(3000.0));
      expect(result.source, RouteSource.cache);
    });

    test('should not use expired cache entries', () async {
      mockOsrmRoutingService.shouldFail = true;
      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      mockRouteCacheService.cache[cacheKey] =
          RouteResult.withoutGeometry(
            distance: 3000.0,
            source: RouteSource.cache,
          ).withCacheMetadata(
            cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
            expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          );

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      // Should fall back to Haversine since cache is expired
      expect(result.source, RouteSource.haversine);
    });
  });

  group('RoutingRepository - Train/Ferry Routing', () {
    test('should use train graph for train mode', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockTrainFerryGraphService.shouldFindPath = true;

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.5995,
        destLng: 121.0000,
        preferredMode: TransportMode.train,
      );

      expect(result.source, RouteSource.graph);
    });

    test('should use ferry graph for ferry mode', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockTrainFerryGraphService.shouldFindPath = true;

      final result = await repository.getRoute(
        originLat: 13.7565,
        originLng: 121.0450,
        destLat: 13.4116,
        destLng: 121.1811,
        preferredMode: TransportMode.ferry,
      );

      expect(result.source, RouteSource.graph);
    });

    test('should fall back when no train/ferry stations nearby', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockTrainFerryGraphService.shouldFindPath = false;

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
        preferredMode: TransportMode.train,
      );

      expect(result.source, RouteSource.haversine);
    });
  });

  group('RoutingRepository - Offline Behavior', () {
    test('should use Haversine when offline', () async {
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      mockOfflineModeService.isCurrentlyOffline = true;

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.source, RouteSource.haversine);
    });

    test('should use cache when offline and cache available', () async {
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      mockOfflineModeService.isCurrentlyOffline = true;
      mockRouteCacheService.shouldReturnCached = true;

      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      mockRouteCacheService.cache[cacheKey] = RouteResult.withoutGeometry(
        distance: 4000.0,
        source: RouteSource.cache,
      );

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.source, RouteSource.cache);
    });

    test(
      'should use train/ferry graph when offline and preferred mode is set',
      () async {
        mockConnectivityService.setConnectivityStatus(
          ConnectivityStatus.offline,
        );
        mockOfflineModeService.isCurrentlyOffline = true;
        mockTrainFerryGraphService.shouldFindPath = true;

        final result = await repository.getRoute(
          originLat: 14.5995,
          originLng: 120.9842,
          destLat: 14.5995,
          destLng: 121.0000,
          preferredMode: TransportMode.train,
        );

        expect(result.source, RouteSource.graph);
      },
    );
  });

  group('RoutingRepository - Accuracy Levels', () {
    test('should set precise accuracy for OSRM results', () async {
      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.accuracy, equals(AccuracyLevel.precise));
    });

    test('should set estimated accuracy for cached results', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockRouteCacheService.shouldReturnCached = true;
      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      mockRouteCacheService.cache[cacheKey] = RouteResult.withoutGeometry(
        distance: 4000.0,
        source: RouteSource.cache,
      );

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.accuracy, equals(AccuracyLevel.estimated));
    });

    test('should set approximate accuracy for Haversine results', () async {
      mockOsrmRoutingService.shouldFail = true;
      mockRouteCacheService.shouldReturnCached = false;

      final result = await repository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      expect(result.accuracy, equals(AccuracyLevel.approximate));
    });
  });

  group('RoutingRepository - Cross-Region Detection', () {
    test('should detect cross-region routes', () async {
      // NCR to Cebu
      final result = await repository.getRoute(
        originLat: 14.5995, // Manila (NCR)
        originLng: 120.9842,
        destLat: 10.3157, // Cebu City (Cebu)
        destLng: 123.8854,
      );

      expect(result.warning, isNotNull);
      expect(result.warning, contains('Cross-region'));
    });

    test('should not warn for same-region routes', () async {
      final result = await repository.getRoute(
        originLat: 14.5995, // Manila
        originLng: 120.9842,
        destLat: 14.6561, // Quezon City
        destLng: 121.0247,
      );

      expect(result.warning, isNull);
    });
  });
}
