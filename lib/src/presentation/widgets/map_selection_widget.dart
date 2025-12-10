import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../services/offline/offline_map_service.dart';

/// A modern, accessible map selection widget.
///
/// Provides interactive map with origin/destination selection,
/// route visualization, and smooth animations following Material 3 guidelines.
/// Supports offline tile caching when [useCachedTiles] is true.
class MapSelectionWidget extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final Function(LatLng)? onOriginSelected;
  final Function(LatLng)? onDestinationSelected;
  final VoidCallback? onSelectionCleared;
  final VoidCallback? onExpandMap;
  final bool isLoading;
  final String? errorMessage;

  /// Whether to use cached tiles from FMTC for offline support.
  final bool useCachedTiles;

  const MapSelectionWidget({
    super.key,
    this.origin,
    this.destination,
    this.routePoints = const [],
    this.onOriginSelected,
    this.onDestinationSelected,
    this.onSelectionCleared,
    this.onExpandMap,
    this.isLoading = false,
    this.errorMessage,
    this.useCachedTiles = true,
  });

  @override
  State<MapSelectionWidget> createState() => _MapSelectionWidgetState();
}

class _MapSelectionWidgetState extends State<MapSelectionWidget>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _markerAnimationController;
  late final Animation<double> _markerBounceAnimation;
  LatLng? _origin;
  LatLng? _destination;
  bool _isMapReady = false;

  // Philippines bounds
  static final _philippinesBounds = LatLngBounds(
    const LatLng(4.215806, 116.931557), // Southwest corner
    const LatLng(21.321780, 126.605345), // Northeast corner
  );

  // Default center (Manila)
  static const _defaultCenter = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _origin = widget.origin;
    _destination = widget.destination;

    // Setup bounce animation for markers
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _markerBounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update local state when widget properties change
    if (widget.origin != oldWidget.origin) {
      _origin = widget.origin;
      if (_origin != null && _isMapReady) {
        _animateToPoint(_origin!);
        _playMarkerBounce();
      }
    }

    if (widget.destination != oldWidget.destination) {
      _destination = widget.destination;
      if (_destination != null && _origin != null && _isMapReady) {
        _fitBoundsAnimated(_origin!, _destination!);
        _playMarkerBounce();
      }
    }
  }

  void _playMarkerBounce() {
    _markerAnimationController.forward().then((_) {
      _markerAnimationController.reverse();
    });
  }

  void _animateToPoint(LatLng point) {
    _mapController.move(point, 13.0);
  }

  void _fitBoundsAnimated(LatLng origin, LatLng destination) {
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
        _playMarkerBounce();
      } else if (_destination == null) {
        _destination = point;
        widget.onDestinationSelected?.call(point);
        _playMarkerBounce();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: _buildSemanticLabel(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Stack(
            children: [
              // Map layer
              _buildMap(context),

              // Loading overlay
              if (widget.isLoading) _buildLoadingOverlay(context),

              // Error overlay
              if (widget.errorMessage != null) _buildErrorOverlay(context),

              // Control buttons
              _buildControlButtons(context),

              // Selection hint
              if (_origin == null && !widget.isLoading)
                _buildSelectionHint(context),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final buffer = StringBuffer('Map selection widget. ');

    if (_origin != null) {
      buffer.write('Origin selected. ');
    }
    if (_destination != null) {
      buffer.write('Destination selected. ');
    }
    if (_origin == null) {
      buffer.write('Tap to select origin. ');
    } else if (_destination == null) {
      buffer.write('Tap to select destination. ');
    }
    if (widget.isLoading) {
      buffer.write('Loading. ');
    }
    if (widget.errorMessage != null) {
      buffer.write('Error: ${widget.errorMessage}');
    }

    return buffer.toString();
  }

  Widget _buildMap(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final markers = _buildMarkers(context);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 11.0,
        minZoom: 5.0,
        onTap: _handleTap,
        cameraConstraint: CameraConstraint.contain(bounds: _philippinesBounds),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onMapReady: () {
          setState(() {
            _isMapReady = true;
          });
        },
      ),
      children: [
        // Base tile layer - use cached tiles when available
        _buildTileLayer(),

        // Route polyline layer
        if (widget.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints,
                strokeWidth: 4.0,
                color: colorScheme.primary,
                borderStrokeWidth: 2.0,
                borderColor: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ],
          ),

        // Markers layer
        MarkerLayer(markers: markers),
      ],
    );
  }

  /// Builds the tile layer, using cached tiles when available.
  Widget _buildTileLayer() {
    if (widget.useCachedTiles) {
      try {
        final offlineMapService = getIt<OfflineMapService>();
        return offlineMapService.getCachedTileLayer();
      } catch (_) {
        // Fall back to network tiles if service not initialized
      }
    }

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.ph_fare_calculator',
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>[];
    final colorScheme = Theme.of(context).colorScheme;

    // Origin marker (circle style)
    if (_origin != null) {
      markers.add(
        Marker(
          point: _origin!,
          width: 44,
          height: 44,
          child: AnimatedBuilder(
            animation: _markerBounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _markerBounceAnimation.value,
                child: child,
              );
            },
            child: _buildOriginMarker(colorScheme),
          ),
        ),
      );
    }

    // Destination marker (pin style)
    if (_destination != null) {
      markers.add(
        Marker(
          point: _destination!,
          width: 44,
          height: 52,
          child: AnimatedBuilder(
            animation: _markerBounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _markerBounceAnimation.value,
                alignment: Alignment.bottomCenter,
                child: child,
              );
            },
            child: _buildDestinationMarker(colorScheme),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildOriginMarker(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4CAF50),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildDestinationMarker(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.tertiary,
            boxShadow: [
              BoxShadow(
                color: colorScheme.tertiary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        // Pin point
        Container(
          width: 3,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.tertiary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        color: colorScheme.surface.withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading route...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expand map button
          if (widget.onExpandMap != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildControlButton(
                context: context,
                icon: Icons.fullscreen,
                tooltip: 'View Full Screen',
                onPressed: widget.onExpandMap,
              ),
            ),

          // Clear selection button
          if (widget.onSelectionCleared != null &&
              (_origin != null || _destination != null))
            _buildControlButton(
              context: context,
              icon: Icons.refresh,
              tooltip: 'Clear Selection',
              onPressed: _clearSelection,
              backgroundColor: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor ?? colorScheme.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionHint(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap on the map to select your origin',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
