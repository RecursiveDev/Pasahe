import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/connectivity_status.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/repositories/routing_repository.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockConnectivityService mockConnectivityService;
  late MockRouteCacheService mockRouteCacheService;
  late MockTrainFerryGraphService mockTrainFerryGraphService;
  late MockHaversineRoutingService mockHaversineRoutingService;
  late MockOsrmRoutingService mockOsrmRoutingService;
  late MockSettingsService mockSettingsService;
  late MockOfflineMapService mockOfflineMapService;
  late OfflineModeService offlineModeService;
  late RoutingRepository routingRepository;

  setUp(() async {
    mockConnectivityService = MockConnectivityService();
    mockRouteCacheService = MockRouteCacheService();
    mockTrainFerryGraphService = MockTrainFerryGraphService();
    mockHaversineRoutingService = MockHaversineRoutingService();
    mockOsrmRoutingService = MockOsrmRoutingService();
    mockSettingsService = MockSettingsService();
    mockOfflineMapService = MockOfflineMapService();

    offlineModeService = OfflineModeService(
      mockConnectivityService,
      mockSettingsService,
      mockOfflineMapService,
    );
    await offlineModeService.initialize();

    routingRepository = RoutingRepository(
      mockOsrmRoutingService,
      mockRouteCacheService,
      mockTrainFerryGraphService,
      mockHaversineRoutingService,
      mockConnectivityService,
      offlineModeService,
    );
  });

  group('Offline Workflow Integration Tests', () {
    test('Workflow 1: Offline mode toggle -> route calculation with fallbacks',
        () async {
      // 1. Start Online
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.online);
      expect(await mockConnectivityService.currentStatus,
          ConnectivityStatus.online);

      // 2. Enable Offline Mode in settings
      await offlineModeService.setOfflineModeEnabled(true);
      expect(offlineModeService.offlineModeEnabled, true);
      expect(offlineModeService.isCurrentlyOffline, true);

      // 3. Calculate route - should skip OSRM even if connected
      final result = await routingRepository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      // Should have fallen back to Haversine (since cache is empty)
      expect(result.source, RouteSource.haversine);
      expect(result.accuracy, equals(offlineModeService.currentAccuracyLevel));
    });

    test('Workflow 2: Online -> offline transition during route calculation',
        () async {
      // 1. Start Online
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.online);

      // 2. Mock OSRM to fail (simulating connection drop during request)
      mockOsrmRoutingService.shouldFail = true;

      // 3. Mock Cache to be available
      mockRouteCacheService.shouldReturnCached = true;
      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      mockRouteCacheService.cache[cacheKey] = RouteResult.withoutGeometry(
        distance: 4500.0,
        source: RouteSource.cache,
      );

      // 4. Calculate route
      final result = await routingRepository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      // Should have used cache after OSRM failed
      expect(result.source, RouteSource.cache);
      expect(result.distance, equals(4500.0));
    });

    test('Workflow 3: Offline -> online transition with cache updates',
        () async {
      // 1. Start Offline
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.offline);
      await Future.delayed(Duration.zero);

      // 2. Calculate route while offline
      final result1 = await routingRepository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );
      expect(result1.source, RouteSource.haversine);

      // 3. Go Online
      mockConnectivityService.setConnectivityStatus(ConnectivityStatus.online);
      await Future.delayed(Duration.zero);

      // 4. Calculate same route again
      final result2 = await routingRepository.getRoute(
        originLat: 14.5995,
        originLng: 120.9842,
        destLat: 14.6561,
        destLng: 121.0247,
      );

      // Should now use OSRM
      expect(result2.source, RouteSource.osrm);

      // 5. Verify it was cached
      final cacheKey = mockRouteCacheService.generateCacheKey(
        14.5995,
        120.9842,
        14.6561,
        121.0247,
      );
      expect(mockRouteCacheService.cache.containsKey(cacheKey), true);
    });
  });
}
