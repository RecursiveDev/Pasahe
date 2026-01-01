import 'dart:convert';
import 'dart:math';

import 'package:directed_graph/directed_graph.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../../models/route_result.dart';
import '../../models/static_fare.dart';
import '../../models/transport_mode.dart';

/// Represents a station or port in the graph.
class StationNode {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String lineId;
  final TransportMode transportMode;

  StationNode({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lineId,
    required this.transportMode,
  });

  @override
  String toString() => name;
}

/// Edge properties for graph.
class EdgeProperties {
  final double distance; // in km

  EdgeProperties({required this.distance});
}

@lazySingleton
class TrainFerryGraphService {
  DirectedGraph<String>? _trainGraph;
  DirectedGraph<String>? _ferryGraph;
  final Map<String, StationNode> _nodes = {};
  final Map<String, Map<String, EdgeProperties>> _edgeProperties = {};
  bool _isInitialized = false;

  /// Map of station names to their approximate coordinates.
  /// In a real app, this would be in a JSON file or database.
  static const Map<String, LatLng> _stationCoords = {
    // MRT-3
    'North Avenue': LatLng(14.6521, 121.0323),
    'Quezon Avenue': LatLng(14.6425, 121.0384),
    'GMA-Kamuning': LatLng(14.6351, 121.0433),
    'Cubao': LatLng(14.6201, 121.0503),
    'Santolan-Annapolis': LatLng(14.6078, 121.0565),
    'Ortigas': LatLng(14.5878, 121.0567),
    'Shaw Boulevard': LatLng(14.5813, 121.0536),
    'Boni': LatLng(14.5739, 121.0481),
    'Guadalupe': LatLng(14.5672, 121.0454),
    'Buendia': LatLng(14.5542, 121.0343),
    'Ayala': LatLng(14.5491, 121.0278),
    'Magallanes': LatLng(14.5420, 121.0195),
    'Taft': LatLng(14.5376, 121.0013),
    
    // LRT-1
    'Baclaran': LatLng(14.5283, 120.9984),
    'EDSA': LatLng(14.5385, 121.0006),
    'Libertad': LatLng(14.5476, 120.9985),
    'Gil Puyat': LatLng(14.5540, 120.9968),
    'Vito Cruz': LatLng(14.5633, 120.9947),
    'Quirino': LatLng(14.5703, 120.9916),
    'Pedro Gil': LatLng(14.5769, 120.9882),
    'UN Avenue': LatLng(14.5826, 120.9847),
    'Central Terminal': LatLng(14.5925, 120.9818),
    'Carriedo': LatLng(14.5996, 120.9815),
    'Doroteo Jose': LatLng(14.6054, 120.9821),
    'Bambang': LatLng(14.6111, 120.9826),
    'Tayuman': LatLng(14.6166, 120.9831),
    'Blumentritt': LatLng(14.6227, 120.9837),
    'Abad Santos': LatLng(14.6304, 120.9812),
    'R. Papa': LatLng(14.6360, 120.9823),
    '5th Avenue': LatLng(14.6444, 120.9837),
    'Monumento': LatLng(14.6542, 120.9838),
    'Balintawak': LatLng(14.6577, 121.0006),
    'Fernando Poe Jr.': LatLng(14.6575, 121.0211),

    // Ferry Ports
    'Batangas': LatLng(13.7565, 121.0450),
    'Calapan': LatLng(13.4116, 121.1811),
    'Puerto Galera': LatLng(13.5015, 120.9547),
    'Manila': LatLng(14.5995, 120.9842),
    'Cebu': LatLng(10.3157, 123.8854),
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _buildTrainGraph();
    await _buildFerryGraph();

    _isInitialized = true;
  }

  Future<void> _buildTrainGraph() async {
    final trainJson = await rootBundle.loadString('assets/data/train_matrix.json');
    final trainData = json.decode(trainJson) as Map<String, dynamic>;

    final edges = <String, Set<String>>{};

    for (final entry in trainData.entries) {
      final lineId = entry.key;
      final fares = (entry.value as List)
          .map((item) => StaticFare.fromJson(item))
          .toList();

      for (final fare in fares) {
        final originId = _generateNodeId(fare.origin, lineId);
        final destId = _generateNodeId(fare.destination, lineId);

        _addNode(fare.origin, lineId, TransportMode.train);
        _addNode(fare.destination, lineId, TransportMode.train);

        edges.putIfAbsent(originId, () => {}).add(destId);
        
        _edgeProperties.putIfAbsent(originId, () => {})[destId] = 
            EdgeProperties(distance: fare.price / 2.0);
      }
    }

    _trainGraph = DirectedGraph<String>(edges);
  }

  Future<void> _buildFerryGraph() async {
    final ferryJson = await rootBundle.loadString('assets/data/ferry_matrix.json');
    final ferryData = json.decode(ferryJson) as Map<String, dynamic>;
    final ferryRoutes = (ferryData['routes'] as List)
        .map((item) => StaticFare.fromJson(item))
        .toList();

    final edges = <String, Set<String>>{};

    for (final fare in ferryRoutes) {
      final lineId = fare.operator ?? 'Ferry';
      final originId = _generateNodeId(fare.origin, lineId);
      final destId = _generateNodeId(fare.destination, lineId);

      _addNode(fare.origin, lineId, TransportMode.ferry);
      _addNode(fare.destination, lineId, TransportMode.ferry);

      edges.putIfAbsent(originId, () => {}).add(destId);
      
      _edgeProperties.putIfAbsent(originId, () => {})[destId] = 
          EdgeProperties(distance: fare.price / 10.0);
    }

    _ferryGraph = DirectedGraph<String>(edges);
  }

  String _generateNodeId(String name, String lineId) {
    return '${lineId}_${name.toLowerCase().replaceAll(' ', '_')}';
  }

  void _addNode(String name, String lineId, TransportMode mode) {
    final id = _generateNodeId(name, lineId);
    if (!_nodes.containsKey(id)) {
      final coords = _stationCoords[name] ?? const LatLng(14.5995, 120.9842);
      _nodes[id] = StationNode(
        id: id,
        name: name,
        latitude: coords.latitude,
        longitude: coords.longitude,
        lineId: lineId,
        transportMode: mode,
      );
    }
  }

  Future<List<StationNode>> findNearbyStations(
    double lat,
    double lng,
    TransportMode mode, {
    double maxDistanceMeters = 5000,
  }) async {
    if (!_isInitialized) await initialize();

    final nearby = <StationNode>[];
    for (final node in _nodes.values) {
      if (node.transportMode != mode) continue;

      final distance = _calculateDistance(lat, lng, node.latitude, node.longitude);
      if (distance <= maxDistanceMeters) {
        nearby.add(node);
      }
    }

    nearby.sort((a, b) {
      final distA = _calculateDistance(lat, lng, a.latitude, a.longitude);
      final distB = _calculateDistance(lat, lng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return nearby;
  }

  Future<RouteResult?> findPath(
    String originNodeId,
    String destNodeId,
    TransportMode mode,
  ) async {
    if (!_isInitialized) await initialize();

    final graph = mode == TransportMode.train ? _trainGraph : _ferryGraph;
    if (graph == null) return null;

    final path = graph.path(originNodeId, destNodeId);
    if (path.isEmpty) return null;

    double totalDistance = 0;
    final geometry = <LatLng>[];

    for (int i = 0; i < path.length; i++) {
      final nodeId = path[i];
      final node = _nodes[nodeId]!;
      geometry.add(LatLng(node.latitude, node.longitude));

      if (i > 0) {
        final prevNodeId = path[i - 1];
        final properties = _edgeProperties[prevNodeId]?[nodeId];
        if (properties != null) {
          totalDistance += properties.distance * 1000;
        } else {
          final prevNode = _nodes[prevNodeId]!;
          totalDistance += _calculateDistance(
            prevNode.latitude,
            prevNode.longitude,
            node.latitude,
            node.longitude,
          );
        }
      }
    }

    final originNode = _nodes[originNodeId]!;
    final destNode = _nodes[destNodeId]!;

    return RouteResult(
      distance: totalDistance,
      duration: (totalDistance / 1000) / (mode == TransportMode.train ? 40 : 20) * 3600,
      geometry: geometry,
      source: RouteSource.graph,
      originCoords: [originNode.latitude, originNode.longitude],
      destCoords: [destNode.latitude, destNode.longitude],
    );
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const d2r = pi / 180.0;
    final dLat = (lat2 - lat1) * d2r;
    final dLng = (lng2 - lng1) * d2r;
    final a = pow(sin(dLat / 2), 2) +
        cos(lat1 * d2r) * cos(lat2 * d2r) * pow(sin(dLng / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return 6371000 * c;
  }
}
