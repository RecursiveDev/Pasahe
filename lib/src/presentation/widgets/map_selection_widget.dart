import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapSelectionWidget extends StatefulWidget {
  final Function(LatLng) onOriginSelected;
  final Function(LatLng) onDestinationSelected;
  final VoidCallback onSelectionCleared;

  const MapSelectionWidget({
    super.key,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onSelectionCleared,
  });

  @override
  State<MapSelectionWidget> createState() => _MapSelectionWidgetState();
}

class _MapSelectionWidgetState extends State<MapSelectionWidget> {
  LatLng? _origin;
  LatLng? _destination;

  // Using a key or controller isn't strictly necessary for the requirements,
  // but good for future extensibility. We'll stick to the requirements.

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (_origin == null) {
        _origin = point;
        widget.onOriginSelected(point);
      } else if (_destination == null) {
        _destination = point;
        widget.onDestinationSelected(point);
      }
      // If both are set, ignore subsequent taps until cleared
    });
  }

  void _clearSelection() {
    setState(() {
      _origin = null;
      _destination = null;
    });
    widget.onSelectionCleared();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

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

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(12.8797, 121.7740),
            initialZoom: 6.0,
            onTap: _handleTap,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ph_fare_estimator',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
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
