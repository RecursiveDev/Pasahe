import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../../models/connectivity_status.dart';
import '../../models/route_result.dart';
import '../connectivity/connectivity_service.dart';
import 'haversine_routing_service.dart';
import 'osrm_routing_service.dart';
import 'route_cache_service.dart';
import 'routing_service.dart';

/// Manages routing with automatic failover between multiple providers.
///
/// Implements the routing strategy from the architecture plan:
/// 1. Check cache first for previously calculated routes
/// 2. Try OSRM if online for accurate road-based routing
/// 3. Fall back to Haversine for straight-line distance estimation
///
/// All successful OSRM routes are cached for future offline use.
@LazySingleton(as: RoutingService)
class RoutingServiceManager implements RoutingService {
  final OsrmRoutingService _osrmService;
  final HaversineRoutingService _haversineService;
  final RouteCacheService _cacheService;
  final ConnectivityService _connectivityService;

  /// Whether to prefer cache over fresh OSRM results.
  /// When true, valid cached routes are returned without OSRM call.
  /// When false, OSRM is tried first (cache used only on failure).
  final bool preferCache;

  /// Creates a new RoutingServiceManager.
  ///
  /// [preferCache] - If true, returns cached routes without trying OSRM.
  ///                 Defaults to true for performance and offline support.
  RoutingServiceManager(
    this._osrmService,
    this._haversineService,
    this._cacheService,
    this._connectivityService,
  ) : preferCache = true;

  /// Gets a route between two points using the failover chain.
  ///
  /// Failover order:
  /// 1. Cache (if preferCache is true and valid cache exists)
  /// 2. OSRM (if online)
  /// 3. Cache (if OSRM fails and cache exists)
  /// 4. Haversine (last resort fallback)
  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final cacheKey = _cacheService.generateCacheKey(
      originLat,
      originLng,
      destLat,
      destLng,
    );

    // Step 1: Check cache first if preferCache is enabled
    if (preferCache) {
      final cachedRoute = await _getCachedRoute(cacheKey);
      if (cachedRoute != null) {
        debugPrint('RoutingServiceManager: Using cached route');
        return cachedRoute;
      }
    }

    // Step 2: Try OSRM if online
    final osrmResult = await _tryOsrm(
      originLat,
      originLng,
      destLat,
      destLng,
      cacheKey,
    );
    if (osrmResult != null) {
      return osrmResult;
    }

    // Step 3: Check cache as fallback (if not already checked)
    if (!preferCache) {
      final cachedRoute = await _getCachedRoute(cacheKey);
      if (cachedRoute != null) {
        debugPrint('RoutingServiceManager: Using cached route (OSRM failed)');
        return cachedRoute;
      }
    }

    // Step 4: Fall back to Haversine
    debugPrint('RoutingServiceManager: Falling back to Haversine');
    return _haversineService.getRoute(originLat, originLng, destLat, destLng);
  }

  /// Gets a route, bypassing the cache for a fresh OSRM result.
  ///
  /// Useful when the user explicitly requests a route refresh.
  Future<RouteResult> getRouteFresh(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final cacheKey = _cacheService.generateCacheKey(
      originLat,
      originLng,
      destLat,
      destLng,
    );

    // Try OSRM first
    final osrmResult = await _tryOsrm(
      originLat,
      originLng,
      destLat,
      destLng,
      cacheKey,
    );
    if (osrmResult != null) {
      return osrmResult;
    }

    // Fall back to cached route
    final cachedRoute = await _getCachedRoute(cacheKey);
    if (cachedRoute != null) {
      debugPrint('RoutingServiceManager: Fresh failed, using cache');
      return cachedRoute;
    }

    // Last resort: Haversine
    debugPrint('RoutingServiceManager: Fresh failed, using Haversine');
    return _haversineService.getRoute(originLat, originLng, destLat, destLng);
  }

  /// Attempts to get a route from OSRM.
  ///
  /// Returns null if OSRM fails or device is offline.
  /// Caches successful results automatically.
  Future<RouteResult?> _tryOsrm(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
    String cacheKey,
  ) async {
    // Check connectivity first to avoid unnecessary network calls
    final connectivity = await _connectivityService.currentStatus;
    if (connectivity.isOffline) {
      debugPrint('RoutingServiceManager: Offline, skipping OSRM');
      return null;
    }

    try {
      debugPrint('RoutingServiceManager: Trying OSRM...');
      final result = await _osrmService.getRoute(
        originLat,
        originLng,
        destLat,
        destLng,
      );

      // Cache successful result
      await _cacheService.cacheRoute(cacheKey, result);
      debugPrint('RoutingServiceManager: OSRM success, cached');

      return result;
    } on NetworkFailure catch (e) {
      debugPrint('RoutingServiceManager: OSRM network error: ${e.message}');
      return null;
    } on ServerFailure catch (e) {
      debugPrint('RoutingServiceManager: OSRM server error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('RoutingServiceManager: OSRM unexpected error: $e');
      return null;
    }
  }

  /// Gets a cached route if available and not expired.
  Future<RouteResult?> _getCachedRoute(String cacheKey) async {
    try {
      return await _cacheService.getCachedRoute(cacheKey);
    } catch (e) {
      debugPrint('RoutingServiceManager: Cache error: $e');
      return null;
    }
  }

  /// Clears the route cache.
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Gets the current cache size.
  int get cacheSize => _cacheService.cacheSize;
}
