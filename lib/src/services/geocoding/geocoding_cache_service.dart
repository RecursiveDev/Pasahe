import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../models/location.dart';

/// Service for caching geocoding results to support offline functionality.
///
/// Handles both forward and reverse geocoding results with a 7-day expiration
/// and an LRU (Least Recently Used) eviction policy for a 500-location limit.
@lazySingleton
class GeocodingCacheService {
  static const String _boxName = 'geocoding_cache';
  static const int _maxEntries = 500;
  static const Duration _cacheDuration = Duration(days: 7);

  /// Initializes the geocoding cache box.
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  /// Retrieves cached locations for a given query or "lat,lng" string.
  ///
  /// Returns null if no cached entry exists or if it has expired.
  Future<List<Location>?> getCachedResults(String key) async {
    final box = Hive.box(_boxName);
    final entry = box.get(key);

    if (entry == null) return null;

    final entryMap = Map<String, dynamic>.from(entry);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(entryMap['timestamp'] as int);

    // Check for expiration
    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      await box.delete(key);
      return null;
    }

    // Update last accessed time for LRU eviction
    entryMap['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
    await box.put(key, entryMap);

    final List<dynamic> locationsJson = entryMap['data'] as List<dynamic>;
    return locationsJson.map((json) {
      final map = Map<String, dynamic>.from(json);
      return Location(
        name: map['display_name'] as String,
        latitude: map['lat'] as double,
        longitude: map['lon'] as double,
      );
    }).toList();
  }

  /// Caches a list of locations for a given query or "lat,lng" string.
  ///
  /// Implements LRU eviction if the cache limit is reached.
  Future<void> cacheResults(String key, List<Location> locations) async {
    final box = Hive.box(_boxName);

    // Evict oldest entry if limit reached and this is a new key
    if (box.length >= _maxEntries && !box.containsKey(key)) {
      await _evictOldest();
    }

    final entry = {
      'data': locations.map((l) => {
        'display_name': l.name,
        'lat': l.latitude,
        'lon': l.longitude,
      }).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'lastAccessed': DateTime.now().millisecondsSinceEpoch,
    };

    await box.put(key, entry);
  }

  /// Finds and deletes the least recently used entry from the cache.
  Future<void> _evictOldest() async {
    final box = Hive.box(_boxName);
    dynamic oldestKey;
    int oldestAccess = DateTime.now().millisecondsSinceEpoch;

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry is Map) {
        final lastAccessed = entry['lastAccessed'] as int? ?? 0;
        if (lastAccessed < oldestAccess) {
          oldestAccess = lastAccessed;
          oldestKey = key;
        }
      }
    }

    if (oldestKey != null) {
      await box.delete(oldestKey);
    }
  }

  /// Clears the entire geocoding cache.
  Future<void> clearCache() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
