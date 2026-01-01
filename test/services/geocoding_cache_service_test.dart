import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:ph_fare_calculator/src/services/geocoding/geocoding_cache_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late GeocodingCacheService service;
  late String tempPath;

  setUpAll(() async {
    tempPath = path.join(Directory.current.path, 'test', 'hive_test_dir');
    final dir = Directory(tempPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    Hive.init(tempPath);
  });

  tearDownAll(() async {
    await Hive.close();
    final dir = Directory(tempPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    service = GeocodingCacheService();
    await service.initialize();
    await service.clearCache();
  });

  group('GeocodingCacheService', () {
    test('should cache and retrieve results', () async {
      final query = 'Manila';
      final locations = [
        Location(name: 'Manila, Philippines', latitude: 14.5995, longitude: 120.9842),
      ];

      await service.cacheResults(query, locations);
      final retrieved = await service.getCachedResults(query);

      expect(retrieved, isNotNull);
      expect(retrieved!.length, 1);
      expect(retrieved[0].name, 'Manila, Philippines');
      expect(retrieved[0].latitude, 14.5995);
    });

    test('should return null for expired results', () async {
      final query = 'Old Search';
      final locations = [
        Location(name: 'Old Place', latitude: 10.0, longitude: 10.0),
      ];

      // Directly put an expired entry into the box
      final box = Hive.box('geocoding_cache');
      final expiredTimestamp = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      
      await box.put(query, {
        'data': locations.map((l) => {
          'display_name': l.name,
          'lat': l.latitude,
          'lon': l.longitude,
        }).toList(),
        'timestamp': expiredTimestamp,
        'lastAccessed': expiredTimestamp,
      });

      final retrieved = await service.getCachedResults(query);
      expect(retrieved, isNull);
    });

    test('should enforce 500 entry limit with LRU eviction', () async {
      // Fill cache to limit
      for (int i = 0; i < 500; i++) {
        await service.cacheResults('query_$i', [
          Location(name: 'Place $i', latitude: i.toDouble(), longitude: i.toDouble()),
        ]);
      }

      final box = Hive.box('geocoding_cache');
      expect(box.length, 500);

      // Access query_0 to make it recent
      await service.getCachedResults('query_0');
      
      // Add one more entry, which should trigger eviction of query_1 (oldest)
      await service.cacheResults('new_query', [
        Location(name: 'New Place', latitude: 999, longitude: 999),
      ]);

      expect(box.length, 500);
      expect(box.containsKey('query_1'), isFalse);
      expect(box.containsKey('query_0'), isTrue);
      expect(box.containsKey('new_query'), isTrue);
    });
  });
}
