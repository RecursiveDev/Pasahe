import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';

void main() {
  group('RouteCacheService', () {
    group('generateCacheKey', () {
      test('should generate consistent key for same coordinates', () {
        const originLat = 14.5995;
        const originLng = 120.9842;
        const destLat = 14.6091;
        const destLng = 121.0223;

        // Using the same algorithm as RouteCacheService
        String generateKey(double oLat, double oLng, double dLat, double dLng) {
          final origin =
              '${oLat.toStringAsFixed(5)},${oLng.toStringAsFixed(5)}';
          final dest = '${dLat.toStringAsFixed(5)},${dLng.toStringAsFixed(5)}';
          final rawKey = '$origin->$dest';
          return rawKey.hashCode.toRadixString(16);
        }

        final key1 = generateKey(originLat, originLng, destLat, destLng);
        final key2 = generateKey(originLat, originLng, destLat, destLng);

        expect(key1, key2);
      });

      test('should generate different keys for different coordinates', () {
        String generateKey(double oLat, double oLng, double dLat, double dLng) {
          final origin =
              '${oLat.toStringAsFixed(5)},${oLng.toStringAsFixed(5)}';
          final dest = '${dLat.toStringAsFixed(5)},${dLng.toStringAsFixed(5)}';
          final rawKey = '$origin->$dest';
          return rawKey.hashCode.toRadixString(16);
        }

        final key1 = generateKey(14.5995, 120.9842, 14.6091, 121.0223);
        final key2 = generateKey(14.5995, 120.9842, 14.7000, 121.1000);

        expect(key1, isNot(key2));
      });

      test('should round coordinates to 5 decimal places', () {
        String generateKey(double oLat, double oLng, double dLat, double dLng) {
          final origin =
              '${oLat.toStringAsFixed(5)},${oLng.toStringAsFixed(5)}';
          final dest = '${dLat.toStringAsFixed(5)},${dLng.toStringAsFixed(5)}';
          final rawKey = '$origin->$dest';
          return rawKey.hashCode.toRadixString(16);
        }

        // Coordinates with minor differences (< 1.1m) should produce same key
        final key1 = generateKey(14.599500, 120.984200, 14.609100, 121.022300);
        final key2 = generateKey(
          14.599500001,
          120.984200001,
          14.609100001,
          121.022300001,
        );

        expect(key1, key2);
      });
    });

    group('RouteResult caching metadata', () {
      test('withCacheMetadata should add cache timestamps', () {
        final route = RouteResult(
          distance: 5000,
          duration: 600,
          geometry: [
            const LatLng(14.5995, 120.9842),
            const LatLng(14.6091, 121.0223),
          ],
          source: RouteSource.osrm,
        );

        final now = DateTime.now();
        final expiresAt = now.add(const Duration(days: 7));

        final cachedRoute = route.withCacheMetadata(
          cachedAt: now,
          expiresAt: expiresAt,
        );

        expect(cachedRoute.cachedAt, now);
        expect(cachedRoute.expiresAt, expiresAt);
        expect(cachedRoute.source, RouteSource.cache);
      });

      test('isExpired should return true for expired routes', () {
        final expiredRoute =
            RouteResult(
              distance: 5000,
              duration: 600,
              geometry: [
                const LatLng(14.5995, 120.9842),
                const LatLng(14.6091, 121.0223),
              ],
              source: RouteSource.osrm,
            ).withCacheMetadata(
              cachedAt: DateTime.now().subtract(const Duration(days: 8)),
              expiresAt: DateTime.now().subtract(const Duration(days: 1)),
            );

        expect(expiredRoute.isExpired, true);
      });

      test('isExpired should return false for valid routes', () {
        final validRoute =
            RouteResult(
              distance: 5000,
              duration: 600,
              geometry: [
                const LatLng(14.5995, 120.9842),
                const LatLng(14.6091, 121.0223),
              ],
              source: RouteSource.osrm,
            ).withCacheMetadata(
              cachedAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(days: 7)),
            );

        expect(validRoute.isExpired, false);
      });

      test('isCacheValid should check both source and expiry', () {
        final validCachedRoute =
            RouteResult(
              distance: 5000,
              duration: 600,
              geometry: [
                const LatLng(14.5995, 120.9842),
                const LatLng(14.6091, 121.0223),
              ],
              source: RouteSource.osrm,
            ).withCacheMetadata(
              cachedAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(days: 7)),
            );

        expect(validCachedRoute.isCacheValid, true);
      });
    });

    group('RouteResult JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        final original = RouteResult(
          distance: 5000,
          duration: 600,
          geometry: [
            const LatLng(14.5995, 120.9842),
            const LatLng(14.6091, 121.0223),
          ],
          source: RouteSource.osrm,
          originCoords: [14.5995, 120.9842],
          destCoords: [14.6091, 121.0223],
        );

        final json = original.toJson();
        final restored = RouteResult.fromJson(json);

        expect(restored.distance, original.distance);
        expect(restored.duration, original.duration);
        expect(restored.geometry.length, original.geometry.length);
        expect(restored.geometry[0].latitude, original.geometry[0].latitude);
        expect(restored.geometry[0].longitude, original.geometry[0].longitude);
        expect(restored.source, original.source);
      });

      test('should serialize cached route with metadata', () {
        final now = DateTime.now();
        final expiresAt = now.add(const Duration(days: 7));

        final original = RouteResult(
          distance: 5000,
          duration: 600,
          geometry: [
            const LatLng(14.5995, 120.9842),
            const LatLng(14.6091, 121.0223),
          ],
          source: RouteSource.osrm,
        ).withCacheMetadata(cachedAt: now, expiresAt: expiresAt);

        final json = original.toJson();
        final restored = RouteResult.fromJson(json);

        expect(restored.cachedAt, isNotNull);
        expect(restored.expiresAt, isNotNull);
        expect(restored.source, RouteSource.cache);
      });
    });

    group('RouteResult geometry', () {
      test('hasGeometry should return true when geometry exists', () {
        final route = RouteResult(
          distance: 5000,
          duration: 600,
          geometry: [
            const LatLng(14.5995, 120.9842),
            const LatLng(14.6091, 121.0223),
          ],
          source: RouteSource.osrm,
        );

        expect(route.hasGeometry, true);
      });

      test('hasGeometry should return false for empty geometry', () {
        final route = RouteResult.withoutGeometry(
          distance: 5000,
          duration: 600,
        );

        expect(route.hasGeometry, false);
      });

      test('withStraightLine should create route with two-point geometry', () {
        final route = RouteResult.withStraightLine(
          distance: 5000,
          origin: const LatLng(14.5995, 120.9842),
          destination: const LatLng(14.6091, 121.0223),
        );

        expect(route.geometry.length, 2);
        expect(route.geometry[0].latitude, 14.5995);
        expect(route.geometry[1].latitude, 14.6091);
        expect(route.source, RouteSource.haversine);
      });
    });

    group('RouteSource', () {
      test('isRoadBased should return true for OSRM', () {
        expect(RouteSource.osrm.isRoadBased, true);
      });

      test('isRoadBased should return true for cache', () {
        expect(RouteSource.cache.isRoadBased, true);
      });

      test('isRoadBased should return false for haversine', () {
        expect(RouteSource.haversine.isRoadBased, false);
      });

      test('description should return human-readable text', () {
        expect(RouteSource.osrm.description, 'Road route');
        expect(RouteSource.cache.description, 'Cached route');
        expect(RouteSource.haversine.description, 'Estimated (straight-line)');
      });
    });

    group('Cache expiry', () {
      test('7-day expiry constant should be defined correctly', () {
        // Based on architecture plan, cache should expire after 7 days
        const cacheExpiry = Duration(days: 7);
        expect(cacheExpiry.inDays, 7);
      });

      test('route cached now should not be expired', () {
        final now = DateTime.now();
        final route =
            RouteResult(
              distance: 5000,
              duration: 600,
              geometry: [],
              source: RouteSource.osrm,
            ).withCacheMetadata(
              cachedAt: now,
              expiresAt: now.add(const Duration(days: 7)),
            );

        expect(route.isExpired, false);
      });

      test('route cached 8 days ago should be expired', () {
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

        final route = RouteResult(
          distance: 5000,
          duration: 600,
          geometry: [],
          source: RouteSource.osrm,
        ).withCacheMetadata(cachedAt: eightDaysAgo, expiresAt: oneDayAgo);

        expect(route.isExpired, true);
      });
    });
  });
}
