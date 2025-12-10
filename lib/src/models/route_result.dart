import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'route_result.g.dart';

/// Indicates the source of a route calculation result.
enum RouteSource {
  /// Route was calculated from OSRM (online road routing).
  osrm,

  /// Route was retrieved from local cache.
  cache,

  /// Route was calculated using Haversine formula (straight-line fallback).
  haversine,
}

/// Extension methods for [RouteSource].
extension RouteSourceX on RouteSource {
  /// Returns a human-readable description of the route source.
  String get description {
    switch (this) {
      case RouteSource.osrm:
        return 'Road route';
      case RouteSource.cache:
        return 'Cached route';
      case RouteSource.haversine:
        return 'Estimated (straight-line)';
    }
  }

  /// Returns true if this route follows actual roads.
  bool get isRoadBased => this == RouteSource.osrm || this == RouteSource.cache;
}

/// Represents the result of a routing calculation.
///
/// Contains the distance, duration, geometry (polyline points), and metadata
/// about the route source and caching.
@HiveType(typeId: 10)
class RouteResult extends HiveObject {
  /// The total distance of the route in meters.
  @HiveField(0)
  final double distance;

  /// The duration of the route in seconds (if available).
  @HiveField(1)
  final double? duration;

  /// The list of coordinates that form the route geometry (polyline).
  /// For services that don't provide geometry (like Haversine), this will be empty.
  /// Stored as a list of [lat, lng] pairs for Hive serialization.
  @HiveField(2)
  final List<List<double>> _geometryData;

  /// The source of this route result.
  @HiveField(3)
  final int _sourceIndex;

  /// When this route was cached (null if not from cache).
  @HiveField(4)
  final DateTime? cachedAt;

  /// When this cached route expires (null if not from cache).
  @HiveField(5)
  final DateTime? expiresAt;

  /// Origin coordinates [lat, lng].
  @HiveField(6)
  final List<double>? originCoords;

  /// Destination coordinates [lat, lng].
  @HiveField(7)
  final List<double>? destCoords;

  /// Creates a new [RouteResult].
  RouteResult({
    required this.distance,
    this.duration,
    List<LatLng> geometry = const [],
    RouteSource source = RouteSource.osrm,
    this.cachedAt,
    this.expiresAt,
    this.originCoords,
    this.destCoords,
    // Optional internal fields for Hive deserialization
    List<List<double>>? geometryData,
    int? sourceIndex,
  }) : _geometryData =
           geometryData ??
           geometry.map((p) => [p.latitude, p.longitude]).toList(),
       _sourceIndex = sourceIndex ?? source.index;

  /// Creates a RouteResult with empty geometry (for fallback services).
  factory RouteResult.withoutGeometry({
    required double distance,
    double? duration,
    RouteSource source = RouteSource.haversine,
  }) {
    return RouteResult(
      distance: distance,
      duration: duration,
      geometry: [],
      source: source,
    );
  }

  /// Creates a RouteResult with a simple straight-line geometry between two points.
  factory RouteResult.withStraightLine({
    required double distance,
    required LatLng origin,
    required LatLng destination,
    double? duration,
    RouteSource source = RouteSource.haversine,
  }) {
    return RouteResult(
      distance: distance,
      duration: duration,
      geometry: [origin, destination],
      source: source,
      originCoords: [origin.latitude, origin.longitude],
      destCoords: [destination.latitude, destination.longitude],
    );
  }

  /// Gets the route geometry as a list of [LatLng] coordinates.
  List<LatLng> get geometry {
    return _geometryData.map((coords) => LatLng(coords[0], coords[1])).toList();
  }

  /// Gets the source of this route result.
  RouteSource get source => RouteSource.values[_sourceIndex];

  /// Returns true if this route has valid geometry for display.
  bool get hasGeometry => _geometryData.isNotEmpty;

  /// Returns true if this cached route has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Returns true if this route is from cache and still valid.
  bool get isCacheValid {
    if (source != RouteSource.cache) return false;
    return !isExpired;
  }

  /// Creates a copy of this route result with cache metadata.
  RouteResult withCacheMetadata({
    required DateTime cachedAt,
    required DateTime expiresAt,
  }) {
    return RouteResult(
      distance: distance,
      duration: duration,
      geometryData: _geometryData,
      sourceIndex: RouteSource.cache.index,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
      originCoords: originCoords,
      destCoords: destCoords,
    );
  }

  /// Creates a copy marked as coming from cache.
  RouteResult asFromCache() {
    return RouteResult(
      distance: distance,
      duration: duration,
      geometryData: _geometryData,
      sourceIndex: RouteSource.cache.index,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
      originCoords: originCoords,
      destCoords: destCoords,
    );
  }

  /// Converts this route result to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
      'geometry': _geometryData,
      'source': _sourceIndex,
      'cachedAt': cachedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'originCoords': originCoords,
      'destCoords': destCoords,
    };
  }

  /// Creates a [RouteResult] from a JSON map.
  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] != null
          ? (json['duration'] as num).toDouble()
          : null,
      geometryData: (json['geometry'] as List<dynamic>)
          .map(
            (coords) => (coords as List<dynamic>)
                .map((c) => (c as num).toDouble())
                .toList(),
          )
          .toList(),
      sourceIndex: json['source'] as int? ?? RouteSource.osrm.index,
      cachedAt: json['cachedAt'] != null
          ? DateTime.parse(json['cachedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      originCoords: json['originCoords'] != null
          ? (json['originCoords'] as List<dynamic>)
                .map((c) => (c as num).toDouble())
                .toList()
          : null,
      destCoords: json['destCoords'] != null
          ? (json['destCoords'] as List<dynamic>)
                .map((c) => (c as num).toDouble())
                .toList()
          : null,
    );
  }

  @override
  String toString() {
    return 'RouteResult('
        'distance: ${distance.toStringAsFixed(0)}m, '
        'duration: ${duration?.toStringAsFixed(0)}s, '
        'points: ${_geometryData.length}, '
        'source: ${source.description}'
        ')';
  }
}
