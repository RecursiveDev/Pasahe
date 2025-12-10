import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../models/route_result.dart';
import 'routing_service.dart';

/// Routing service that uses OSRM (Open Source Routing Machine) for
/// calculating road-based routes with full geometry.
///
/// OSRM provides accurate road distances and complete polyline geometry
/// that follows actual roads, unlike straight-line Haversine calculations.
@lazySingleton
class OsrmRoutingService implements RoutingService {
  /// Default OSRM public server URL.
  static const String _defaultBaseUrl = AppConstants.kOsrmBaseUrl;

  /// Default request timeout duration.
  static const Duration _defaultTimeout = Duration(seconds: 10);

  /// The OSRM API base URL.
  final String baseUrl;

  /// HTTP client for making requests.
  final http.Client _httpClient;

  /// Request timeout duration.
  final Duration timeout;

  /// Creates an OSRM routing service with default configuration.
  OsrmRoutingService()
    : baseUrl = _defaultBaseUrl,
      timeout = _defaultTimeout,
      _httpClient = http.Client();

  /// Creates an OSRM routing service with custom configuration.
  ///
  /// [baseUrl] - The OSRM server URL (defaults to public server).
  /// [httpClient] - Custom HTTP client (optional, for testing).
  /// [timeout] - Request timeout (defaults to 10 seconds).
  OsrmRoutingService.custom({
    String? baseUrl,
    http.Client? httpClient,
    Duration? timeout,
  }) : baseUrl = baseUrl ?? _defaultBaseUrl,
       timeout = timeout ?? _defaultTimeout,
       _httpClient = httpClient ?? http.Client();

  /// Fetches the route information between two coordinates.
  ///
  /// [originLat], [originLng]: Latitude and Longitude of the starting point.
  /// [destLat], [destLng]: Latitude and Longitude of the destination.
  ///
  /// Returns a RouteResult containing distance, duration, and geometry.
  /// Throws [NetworkFailure] if the network request fails.
  /// Throws [ServerFailure] if OSRM returns an error.
  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    // OSRM expects {longitude},{latitude}
    // Request geometries as geojson for easier parsing
    final requestUrl =
        '$baseUrl/route/v1/driving/'
        '$originLng,$originLat;$destLng,$destLat'
        '?overview=full&geometries=geojson';

    debugPrint('OSRM request: $requestUrl');

    try {
      final response = await _httpClient
          .get(Uri.parse(requestUrl))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return _parseOsrmResponse(
          response.body,
          originLat,
          originLng,
          destLat,
          destLng,
        );
      } else if (response.statusCode == 429) {
        throw const ServerFailure(
          'OSRM rate limit exceeded. Please try again later.',
        );
      } else if (response.statusCode >= 500) {
        throw ServerFailure(
          'OSRM server error. Status code: ${response.statusCode}',
        );
      } else {
        throw ServerFailure(
          'Failed to load route. Status code: ${response.statusCode}',
        );
      }
    } on ServerFailure {
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('OSRM client error: $e');
      throw NetworkFailure('Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      debugPrint('OSRM error: $e');
      throw NetworkFailure('Error fetching route: $e');
    }
  }

  /// Parses the OSRM response and extracts route information.
  RouteResult _parseOsrmResponse(
    String responseBody,
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final code = data['code'] as String?;

    if (code != 'Ok') {
      throw ServerFailure(_getOsrmErrorMessage(code));
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const ServerFailure('No route found between the specified points.');
    }

    final route = routes[0] as Map<String, dynamic>;
    final distance = (route['distance'] as num).toDouble();
    final duration = (route['duration'] as num?)?.toDouble();

    // Parse geometry from GeoJSON format
    final geometry = _parseGeometry(route);

    debugPrint(
      'OSRM route: ${distance.toStringAsFixed(0)}m, '
      '${geometry.length} points',
    );

    return RouteResult(
      distance: distance,
      duration: duration,
      geometry: geometry,
      source: RouteSource.osrm,
      originCoords: [originLat, originLng],
      destCoords: [destLat, destLng],
    );
  }

  /// Parses the geometry from OSRM GeoJSON response.
  List<LatLng> _parseGeometry(Map<String, dynamic> route) {
    final geometry = <LatLng>[];

    final geometryData = route['geometry'];
    if (geometryData == null) {
      return geometry;
    }

    // Handle GeoJSON format
    if (geometryData is Map<String, dynamic>) {
      final coordinates = geometryData['coordinates'] as List<dynamic>?;
      if (coordinates != null) {
        for (final coord in coordinates) {
          if (coord is List && coord.length >= 2) {
            // GeoJSON format is [longitude, latitude]
            geometry.add(
              LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ),
            );
          }
        }
      }
    }

    return geometry;
  }

  /// Gets a human-readable error message for OSRM error codes.
  String _getOsrmErrorMessage(String? code) {
    switch (code) {
      case 'InvalidUrl':
        return 'Invalid route request URL.';
      case 'InvalidService':
        return 'Invalid OSRM service requested.';
      case 'InvalidVersion':
        return 'Invalid OSRM API version.';
      case 'InvalidOptions':
        return 'Invalid route options.';
      case 'InvalidQuery':
        return 'Invalid route query parameters.';
      case 'InvalidValue':
        return 'Invalid coordinate values.';
      case 'NoSegment':
        return 'Could not find a route segment near the specified point.';
      case 'TooBig':
        return 'Route request too large.';
      case 'NoRoute':
        return 'No route found between the specified points.';
      case 'NoTable':
        return 'No distance table found.';
      case 'NotImplemented':
        return 'This OSRM feature is not implemented.';
      default:
        return 'OSRM error: ${code ?? 'Unknown'}';
    }
  }

  /// Disposes of resources.
  void dispose() {
    _httpClient.close();
  }
}
