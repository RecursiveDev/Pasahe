import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapSelectionWidget extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final Function(LatLng)? onOriginSelected;
  final Function(LatLng)? onDestinationSelected;
  final VoidCallback? onSelectionCleared;

  const MapSelectionWidget({
    super.key,
    this.origin,
    this.destination,
    this.routePoints = const [],
    this.onOriginSelected,
    this.onDestinationSelected,
    this.onSelectionCleared,
  });

  @override
  State<MapSelectionWidget> createState() => _MapSelectionWidgetState();
}

class _MapSelectionWidgetState extends State<MapSelectionWidget> {
  late final MapController _mapController;
  LatLng? _origin;
  LatLng? _destination;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _origin = widget.origin;
    _destination = widget.destination;
  }

  @override
  void didUpdateWidget(MapSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update local state when widget properties change
    if (widget.origin != oldWidget.origin) {
      _origin = widget.origin;
      if (_origin != null) {
        _moveCameraToPoint(_origin!);
      }
    }

    if (widget.destination != oldWidget.destination) {
      _destination = widget.destination;
      if (_destination != null && _origin != null) {
        _fitBounds(_origin!, _destination!);
      }
    }
  }

  void _moveCameraToPoint(LatLng point) {
    _mapController.move(point, 13.0);
  }

  void _fitBounds(LatLng origin, LatLng destination) {
    final bounds = LatLngBounds(origin, destination);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (_origin == null) {
        _origin = point;
        widget.onOriginSelected?.call(point);
      } else if (_destination == null) {
        _destination = point;
        widget.onDestinationSelected?.call(point);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _origin = null;
      _destination = null;
    });
    widget.onSelectionCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // Add origin marker
    if (_origin != null) {
      markers.add(
        Marker(
          point: _origin!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }

    // Add destination marker
    if (_destination != null) {
      markers.add(
        Marker(
          point: _destination!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    // Define Philippines bounds to restrict map view
    final philippinesBounds = LatLngBounds(
      const LatLng(4.215806, 116.931557), // Southwest corner
      const LatLng(21.321780, 126.605345), // Northeast corner
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(
              14.5995,
              120.9842,
            ), // Manila coordinates
            initialZoom: 11.0,
            minZoom: 5.0, // Prevent zooming out too far
            onTap: _handleTap,
            cameraConstraint: CameraConstraint.contain(
              bounds: philippinesBounds,
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ph_fare_calculator',
            ),
            // Add polyline layer for route visualization
            if (widget.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (widget.onSelectionCleared != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
              child: const Icon(Icons.refresh),
            ),
          ),
      ],
    );
  }
}
