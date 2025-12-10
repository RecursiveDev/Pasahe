import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../models/route_result.dart';

/// Service for caching route results using Hive for persistent storage.
///
/// Implements a 7-day cache expiry policy as specified in the architecture plan.
/// Cache keys are generated from origin/destination coordinates to ensure
/// consistent lookups regardless of route direction.
@lazySingleton
class RouteCacheService {
  /// The Hive box name for storing cached routes.
  static const String _boxName = 'route_cache';

  /// Cache expiry duration (7 days as per architecture plan).
  static const Duration cacheExpiry = Duration(days: 7);

  /// The Hive box instance for route caching.
  Box<String>? _box;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// Initializes the cache service.
  ///
  /// Registers the Hive adapter and opens the cache box.
  /// This should be called during app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register the RouteResult adapter if not already registered
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(RouteResultAdapter());
      }

      // Open the box for string storage (JSON serialized routes)
      _box = await Hive.openBox<String>(_boxName);
      _isInitialized = true;

      // Clean up expired entries on initialization
      await _cleanupExpiredEntries();

      debugPrint(
        'RouteCacheService initialized with ${_box!.length} cached routes',
      );
    } catch (e) {
      debugPrint('Failed to initialize RouteCacheService: $e');
      rethrow;
    }
  }

  /// Generates a unique cache key from origin and destination coordinates.
  ///
  /// Uses a simple hash of the coordinates to create a consistent key.
  String generateCacheKey(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    // Round coordinates to 5 decimal places (~1.1m precision)
    // to allow for minor GPS variations to still hit cache
    final origin =
        '${originLat.toStringAsFixed(5)},${originLng.toStringAsFixed(5)}';
    final dest = '${destLat.toStringAsFixed(5)},${destLng.toStringAsFixed(5)}';
    final rawKey = '$origin->$dest';

    // Simple hash for consistent key format
    return rawKey.hashCode.toRadixString(16);
  }

  /// Retrieves a cached route by its key.
  ///
  /// Returns `null` if the route is not found or has expired.
  Future<RouteResult?> getCachedRoute(String cacheKey) async {
    if (!_isInitialized || _box == null) {
      debugPrint('RouteCacheService not initialized');
      return null;
    }

    try {
      final json = _box!.get(cacheKey);
      if (json == null) {
        debugPrint('Cache miss for key: $cacheKey');
        return null;
      }

      final route = RouteResult.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      // Check if cache has expired
      if (route.isExpired) {
        debugPrint('Cache expired for key: $cacheKey');
        await _box!.delete(cacheKey);
        return null;
      }

      debugPrint('Cache hit for key: $cacheKey');
      return route.asFromCache();
    } catch (e) {
      debugPrint('Error retrieving cached route: $e');
      return null;
    }
  }

  /// Retrieves a cached route by coordinates.
  ///
  /// Convenience method that generates the cache key internally.
  Future<RouteResult?> getCachedRouteByCoords(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final key = generateCacheKey(originLat, originLng, destLat, destLng);
    return getCachedRoute(key);
  }

  /// Caches a route result.
  ///
  /// Adds cache metadata (cachedAt, expiresAt) to the route before storing.
  Future<void> cacheRoute(String cacheKey, RouteResult route) async {
    if (!_isInitialized || _box == null) {
      debugPrint('RouteCacheService not initialized, skipping cache');
      return;
    }

    try {
      final now = DateTime.now();
      final cachedRoute = route.withCacheMetadata(
        cachedAt: now,
        expiresAt: now.add(cacheExpiry),
      );

      final json = jsonEncode(cachedRoute.toJson());
      await _box!.put(cacheKey, json);

      debugPrint('Route cached with key: $cacheKey');
    } catch (e) {
      debugPrint('Error caching route: $e');
    }
  }

  /// Caches a route result by coordinates.
  ///
  /// Convenience method that generates the cache key internally.
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

  /// Removes a cached route by its key.
  Future<void> removeCachedRoute(String cacheKey) async {
    if (!_isInitialized || _box == null) return;

    try {
      await _box!.delete(cacheKey);
      debugPrint('Route removed from cache: $cacheKey');
    } catch (e) {
      debugPrint('Error removing cached route: $e');
    }
  }

  /// Clears all cached routes.
  Future<void> clearCache() async {
    if (!_isInitialized || _box == null) return;

    try {
      await _box!.clear();
      debugPrint('Route cache cleared');
    } catch (e) {
      debugPrint('Error clearing route cache: $e');
    }
  }

  /// Gets the number of cached routes.
  int get cacheSize => _box?.length ?? 0;

  /// Gets all cached route keys.
  List<String> get cachedKeys => _box?.keys.cast<String>().toList() ?? [];

  /// Cleans up expired cache entries.
  Future<void> _cleanupExpiredEntries() async {
    if (!_isInitialized || _box == null) return;

    final keysToRemove = <String>[];

    for (final key in _box!.keys) {
      try {
        final json = _box!.get(key);
        if (json != null) {
          final route = RouteResult.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          );
          if (route.isExpired) {
            keysToRemove.add(key as String);
          }
        }
      } catch (e) {
        // Remove corrupted entries
        keysToRemove.add(key as String);
      }
    }

    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        await _box!.delete(key);
      }
      debugPrint(
        'Cleaned up ${keysToRemove.length} expired/corrupted cache entries',
      );
    }
  }

  /// Disposes of the cache service.
  Future<void> dispose() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _isInitialized = false;
  }
}
