import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/services/routing/haversine_routing_service.dart';

void main() {
  late HaversineRoutingService service;

  setUp(() {
    service = HaversineRoutingService();
  });

  group('HaversineRoutingService', () {
    test('returns 0 when origin and destination are the same', () async {
      final result = await service.getRoute(
        14.5995,
        120.9842,
        14.5995,
        120.9842,
      );
      expect(result.distance, 0.0);
      // Same origin/destination still returns a 2-point geometry for display
      expect(result.geometry, hasLength(2));
      expect(result.source, RouteSource.haversine);
    });

    test(
      'returns correct distance for 1 degree longitude at equator',
      () async {
        // 1 degree longitude at equator is approx 111,195 meters
        // Formula: R * (pi/180)
        const expectedDistance = 6371000 * (pi / 180);
        final result = await service.getRoute(0, 0, 0, 1);

        // Allow for small floating point differences
        expect(result.distance, closeTo(expectedDistance, 0.1));
        // Haversine now returns interpolated points for straight line display
        expect(result.geometry, isNotEmpty);
        expect(result.source, RouteSource.haversine);
      },
    );

    test('returns correct distance for 1 degree latitude', () async {
      // 1 degree latitude is approx 111,195 meters everywhere
      const expectedDistance = 6371000 * (pi / 180);
      final result = await service.getRoute(0, 0, 1, 0);

      expect(result.distance, closeTo(expectedDistance, 0.1));
      // Haversine now returns interpolated points for straight line display
      expect(result.geometry, isNotEmpty);
      expect(result.source, RouteSource.haversine);
    });

    test(
      'calculates distance between Manila and Makati (approximate check)',
      () async {
        // Manila
        const double lat1 = 14.5995;
        const double lng1 = 120.9842;
        // Makati
        const double lat2 = 14.5547;
        const double lng2 = 121.0244;

        // Distance should be roughly 6-7 km (6000-7000 meters)
        final result = await service.getRoute(lat1, lng1, lat2, lng2);

        expect(result.distance, greaterThan(5000));
        expect(result.distance, lessThan(8000));
        // Haversine now returns interpolated points for straight line display
        expect(result.geometry, isNotEmpty);
        expect(result.source, RouteSource.haversine);
      },
    );

    test(
      'handles negative coordinates (Western/Southern Hemisphere)',
      () async {
        // Distance from (0, -1) to (0, 1) is 2 degrees longitude
        const expectedDistance = 6371000 * (2 * pi / 180);
        final result = await service.getRoute(0, -1, 0, 1);

        expect(result.distance, closeTo(expectedDistance, 0.1));
        // Haversine now returns interpolated points for straight line display
        expect(result.geometry, isNotEmpty);
        expect(result.source, RouteSource.haversine);
      },
    );
  });
}
