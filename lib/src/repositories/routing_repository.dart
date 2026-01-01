import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/region_constants.dart';
import '../models/route_result.dart';
import '../models/transport_mode.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/offline/offline_mode_service.dart';
import '../services/routing/route_cache_service.dart';
import '../services/routing/routing_service.dart';
import '../services/routing/train_ferry_graph_service.dart';

@lazySingleton
class RoutingRepository {
  final RoutingService _osrmService;
  final RouteCacheService _cacheService;
  final TrainFerryGraphService _graphService;
  final RoutingService _haversineService;
  final ConnectivityService _connectivityService;
  final OfflineModeService _offlineModeService;

  RoutingRepository(
    @Named('osrm') this._osrmService,
    this._cacheService,
    this._graphService,
    @Named('haversine') this._haversineService,
    this._connectivityService,
    this._offlineModeService,
  );

  /// Gets a route between two points using the fallback hierarchy.
  ///
  /// Hierarchy:
  /// 1. OSRM (if online, 3s timeout)
  /// 2. Cache (if OSRM fails or offline)
  /// 3. Train/Ferry Graph (if applicable)
  /// 4. Haversine (last resort)
  Future<RouteResult> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    TransportMode? preferredMode,
    bool forceOffline = false,
  }) async {
    // Check for cross-region route
    final warning = _detectCrossRegion(originLat, originLng, destLat, destLng);

    // Level 1: OSRM (Online Road Routing)
    final isOffline = _offlineModeService.isCurrentlyOffline;
    if (!forceOffline && !isOffline) {
      try {
        debugPrint('RoutingRepository: Trying OSRM...');
        final result = await _osrmService
            .getRoute(originLat, originLng, destLat, destLng)
            .timeout(const Duration(seconds: 3));

        // Cache successful result
        final cacheKey = _cacheService.generateCacheKey(
          originLat,
          originLng,
          destLat,
          destLng,
        );
        await _cacheService.cacheRoute(cacheKey, result);

        return _applyMetadata(result, warning: warning);
      } catch (e) {
        debugPrint('RoutingRepository: OSRM failed or timed out: $e');
      }
    }

    // Level 2: Route Cache
    final cacheKey = _cacheService.generateCacheKey(
      originLat,
      originLng,
      destLat,
      destLng,
    );
    final cachedRoute = await _cacheService.getCachedRoute(cacheKey);
    if (cachedRoute != null && !cachedRoute.isExpired) {
      debugPrint('RoutingRepository: Using cached route');
      return _applyMetadata(cachedRoute.asFromCache(), warning: warning);
    }

    // Level 3: Train/Ferry Graph
    if (preferredMode == TransportMode.train ||
        preferredMode == TransportMode.ferry) {
      final graphResult = await _tryGraphRouting(
        originLat,
        originLng,
        destLat,
        destLng,
        preferredMode!,
      );
      if (graphResult != null) {
        debugPrint('RoutingRepository: Using graph routing');
        return _applyMetadata(graphResult, warning: warning);
      }
    }

    // Level 4: Haversine
    debugPrint('RoutingRepository: Falling back to Haversine');
    final haversineResult = await _haversineService.getRoute(
      originLat,
      originLng,
      destLat,
      destLng,
    );
    return _applyMetadata(haversineResult, warning: warning);
  }

  Future<RouteResult?> _tryGraphRouting(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
    TransportMode mode,
  ) async {
    final originNearby = await _graphService.findNearbyStations(
      originLat,
      originLng,
      mode,
    );
    final destNearby = await _graphService.findNearbyStations(
      destLat,
      destLng,
      mode,
    );

    if (originNearby.isEmpty || destNearby.isEmpty) return null;

    // Try to find a path between the closest stations
    for (final origin in originNearby.take(3)) {
      for (final dest in destNearby.take(3)) {
        final result = await _graphService.findPath(origin.id, dest.id, mode);
        if (result != null) return result;
      }
    }

    return null;
  }

  String? _detectCrossRegion(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    final origin = LatLng(originLat, originLng);
    final dest = LatLng(destLat, destLng);

    final originRegion = _getRegion(origin);
    final destRegion = _getRegion(dest);

    if (originRegion != destRegion &&
        originRegion != Region.nationwide &&
        destRegion != Region.nationwide) {
      return 'Cross-region route detected. Fares may vary across regional boundaries.';
    }
    return null;
  }

  Region _getRegion(LatLng point) {
    if (RegionConstants.ncrBounds.contains(point)) return Region.ncr;
    if (RegionConstants.cebuBounds.contains(point)) return Region.cebu;
    if (RegionConstants.davaoBounds.contains(point)) return Region.davao;
    if (RegionConstants.cdoBounds.contains(point)) return Region.cdo;
    return Region.nationwide;
  }

  RouteResult _applyMetadata(RouteResult result, {String? warning}) {
    // Ensure accuracy level is correctly set based on source if not already
    final accuracy = result.source.defaultAccuracy;

    return RouteResult(
      distance: result.distance,
      duration: result.duration,
      geometry: result.geometry,
      source: result.source,
      cachedAt: result.cachedAt,
      expiresAt: result.expiresAt,
      originCoords: result.originCoords,
      destCoords: result.destCoords,
      accuracy: accuracy,
      warning: warning ?? result.warning,
    );
  }
}
