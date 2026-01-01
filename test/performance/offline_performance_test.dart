import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';

import '../helpers/mocks.dart';

void main() {
  group('Offline Mode Performance Benchmarks', () {
    late MockRouteCacheService routeCache;
    late MockGeocodingCacheService geocodingCache;
    late RoutingRepository routingRepository;
    late MockOsrmRoutingService osrmService;
    late MockHaversineRoutingService haversineService;
    late MockConnectivityService connectivityService;
    late MockTrainFerryGraphService graphService;
    late MockOfflineModeService offlineModeService;

    setUp(() {
      routeCache = MockRouteCacheService();
      geocodingCache = MockGeocodingCacheService();
      osrmService = MockOsrmRoutingService();
      haversineService = MockHaversineRoutingService();
      connectivityService = MockConnectivityService();
      graphService = MockTrainFerryGraphService();
      offlineModeService = MockOfflineModeService();

      routingRepository = RoutingRepository(
        osrmService,
        routeCache,
        graphService,
        haversineService,
        connectivityService,
        offlineModeService,
      );
    });

    test('Benchmark: RouteCacheService operations', () async {
      final stopwatch = Stopwatch()..start();
      
      const iterations = 100;
      
      // 1. Bulk Write
      stopwatch.reset();
      for (var i = 0; i < iterations; i++) {
        final key = 'key_$i';
        await routeCache.cacheRoute(key, RouteResult.withoutGeometry(distance: 1000.0 * i));
      }
      final writeTime = stopwatch.elapsedMilliseconds;
      print('RouteCache Write ($iterations ops): ${writeTime}ms (${writeTime / iterations}ms/op)');

      // 2. Bulk Read
      stopwatch.reset();
      for (var i = 0; i < iterations; i++) {
        final key = 'key_$i';
        await routeCache.getCachedRoute(key);
      }
      final readTime = stopwatch.elapsedMilliseconds;
      print('RouteCache Read ($iterations ops): ${readTime}ms (${readTime / iterations}ms/op)');

      expect(writeTime, lessThan(500)); // Reasonable limit for 100 mock ops
      expect(readTime, lessThan(500));
    });

    test('Benchmark: RoutingRepository fallback timing', () async {
      final stopwatch = Stopwatch();

      // Case 1: OSRM (Level 1)
      connectivityService.setConnectivityStatus(ConnectivityStatus.online);
      stopwatch.start();
      await routingRepository.getRoute(
        originLat: 14.5, originLng: 121.0, destLat: 14.6, destLng: 121.1
      );
      stopwatch.stop();
      print('Routing Level 1 (OSRM): ${stopwatch.elapsedMicroseconds}us');

      // Case 2: Cache (Level 2)
      osrmService.shouldFail = true;
      routeCache.shouldReturnCached = true;
      final cacheKey = routeCache.generateCacheKey(14.5, 121.0, 14.6, 121.1);
      routeCache.cache[cacheKey] = RouteResult.withoutGeometry(distance: 5000);
      
      stopwatch.reset();
      stopwatch.start();
      await routingRepository.getRoute(
        originLat: 14.5, originLng: 121.0, destLat: 14.6, destLng: 121.1
      );
      stopwatch.stop();
      print('Routing Level 2 (Cache): ${stopwatch.elapsedMicroseconds}us');

      // Case 3: Haversine (Level 4)
      routeCache.shouldReturnCached = false;
      stopwatch.reset();
      stopwatch.start();
      await routingRepository.getRoute(
        originLat: 14.5, originLng: 121.0, destLat: 14.6, destLng: 121.1
      );
      stopwatch.stop();
      print('Routing Level 4 (Haversine): ${stopwatch.elapsedMicroseconds}us');
      
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
    
    test('Benchmark: GeocodingCacheService operations', () async {
      final stopwatch = Stopwatch()..start();
      const iterations = 100;
      
      for (var i = 0; i < iterations; i++) {
        final key = 'query_$i';
        await geocodingCache.cacheResults(key, []);
        await geocodingCache.getCachedResults(key);
      }
      
      final totalTime = stopwatch.elapsedMilliseconds;
      print('GeocodingCache ($iterations write+read): ${totalTime}ms');
      expect(totalTime, lessThan(500));
    });
  });
}
