import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/core/errors/failures.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_service.dart';
import '../helpers/mocks.dart';

void main() {
  late OpenStreetMapGeocodingService service;
  late MockGeocodingCacheService mockCache;
  late MockOfflineModeService mockOfflineMode;

  setUp(() {
    mockCache = MockGeocodingCacheService();
    mockOfflineMode = MockOfflineModeService();
    service = OpenStreetMapGeocodingService(mockCache, mockOfflineMode);
  });

  group('OpenStreetMapGeocodingService', () {
    test('should return coordinates when query is in lat,lng format', () async {
      final query = '14.5995, 120.9842';
      final results = await service.getLocations(query);

      expect(results.length, 1);
      expect(results[0].latitude, 14.5995);
      expect(results[0].longitude, 120.9842);
      expect(results[0].name, contains('14.599500'));
    });

    test('should return cached results when offline', () async {
      final query = 'Manila';
      final cachedLocations = [
        Location(name: 'Cached Manila', latitude: 14.5, longitude: 120.9),
      ];
      
      mockCache.cache['manila'] = cachedLocations;
      mockOfflineMode.isCurrentlyOffline = true;

      final results = await service.getLocations(query);

      expect(results.length, 1);
      expect(results[0].name, 'Cached Manila');
    });

    test('should throw NetworkFailure when offline and no cache', () async {
      final query = 'Unknown';
      mockOfflineMode.isCurrentlyOffline = true;

      expect(
        () => service.getLocations(query),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('should return coordinates name for reverse geocoding when offline', () async {
      mockOfflineMode.isCurrentlyOffline = true;
      final result = await service.getAddressFromLatLng(14.0, 121.0);

      expect(result.name, contains('14.000000'));
      expect(result.latitude, 14.0);
      expect(result.longitude, 121.0);
    });

    test('should return cached reverse geocoding result', () async {
      final lat = 14.123456;
      final lon = 121.123456;
      final cacheKey = '14.123456,121.123456';
      final cachedLocation = Location(name: 'Cached Address', latitude: lat, longitude: lon);
      
      mockCache.cache[cacheKey] = [cachedLocation];

      final result = await service.getAddressFromLatLng(lat, lon);

      expect(result.name, 'Cached Address');
    });
  });
}
