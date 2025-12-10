import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../services/offline/offline_map_service.dart';
import '../widgets/offline_indicator.dart';

/// A modern full-screen map picker with floating UI elements and animations.
/// Allows users to select a location by dragging the map or tapping.
/// Supports offline tile caching via FMTC.
class MapPickerScreen extends StatefulWidget {
  /// Initial location to center the map on
  final LatLng? initialLocation;

  /// Title for the app bar
  final String title;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.title = 'Select Location',
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  LatLng? _selectedLocation;
  bool _isMapMoving = false;
  String _addressText = 'Move map to select location';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Animation controller for pin bounce effect
  late final AnimationController _pinAnimationController;
  late final Animation<double> _pinBounceAnimation;
  late final Animation<double> _pinScaleAnimation;

  // Default center: Manila, Philippines
  static const LatLng _defaultCenter = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? _defaultCenter;

    // Initialize pin animation controller
    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Bounce animation for vertical movement
    _pinBounceAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: _pinAnimationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.bounceOut,
      ),
    );

    // Scale animation for pin
    _pinScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pinAnimationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Update address on init
    _updateAddress(_selectedLocation!);
  }

  @override
  void dispose() {
    _pinAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      setState(() => _isMapMoving = true);
      _pinAnimationController.forward();
    } else if (event is MapEventMoveEnd) {
      setState(() {
        _isMapMoving = false;
        _selectedLocation = _mapController.camera.center;
      });
      _pinAnimationController.reverse();
      _updateAddress(_mapController.camera.center);
    } else if (event is MapEventMove) {
      // Update position during movement
      setState(() {
        _selectedLocation = _mapController.camera.center;
      });
    }
  }

  void _updateAddress(LatLng location) {
    // In a real app, this would call a geocoding service
    // For now, we display the coordinates in a formatted way
    setState(() {
      _addressText =
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }

  void _goToCurrentLocation() {
    // In a real app, this would use geolocator to get current position
    // For now, we center on Manila
    _mapController.move(_defaultCenter, 15.0);
    setState(() {
      _selectedLocation = _defaultCenter;
    });
    _updateAddress(_defaultCenter);
  }

  void _onSearchSubmitted(String query) {
    // In a real app, this would search for the location
    // For now, we just close the search
    setState(() {
      _isSearching = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, theme, colorScheme),
      body: Stack(
        children: [
          // Full screen map
          _buildMap(),

          // Center pin with animation
          _buildAnimatedCenterPin(colorScheme),

          // Floating search bar at top
          _buildFloatingSearchBar(theme, colorScheme),

          // Offline indicator badge (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            right: 16,
            child: const OfflineIndicatorBadge(),
          ),

          // Bottom location card
          _buildBottomLocationCard(theme, colorScheme),
        ],
      ),
      // Current location FAB
      floatingActionButton: _buildCurrentLocationFab(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Semantics(
        label: 'Go back',
        button: true,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildMap() {
    return Semantics(
      label: 'Map view for selecting location',
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation ?? _defaultCenter,
          initialZoom: 15.0,
          minZoom: 5.0,
          maxZoom: 18.0,
          onMapEvent: _handleMapEvent,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [_buildTileLayer()],
      ),
    );
  }

  /// Builds the tile layer, using cached tiles when available.
  Widget _buildTileLayer() {
    try {
      final offlineMapService = getIt<OfflineMapService>();
      return offlineMapService.getCachedTileLayer();
    } catch (_) {
      // Fall back to network tiles if service not initialized
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.ph_fare_calculator',
      );
    }
  }

  Widget _buildAnimatedCenterPin(ColorScheme colorScheme) {
    return Center(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pinAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _pinBounceAnimation.value - 25),
              child: Transform.scale(
                scale: _pinScaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pin shadow
                    Container(
                      width: 12,
                      height: 6,
                      margin: const EdgeInsets.only(top: 50),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Offset to position pin properly
                    Transform.translate(
                      offset: const Offset(0, -56),
                      child: _buildPinMarker(colorScheme),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinMarker(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(Icons.place, color: colorScheme.onPrimary, size: 28),
          ),
          // Pin stem
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72, // Below app bar
      left: 16,
      right: 16,
      child: Semantics(
        label: 'Search for a location',
        textField: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onTap: () => setState(() => _isSearching = true),
            onSubmitted: _onSearchSubmitted,
            decoration: InputDecoration(
              hintText: 'Search location...',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
              ),
              suffixIcon: _isSearching || _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _isSearching = false);
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLocationCard(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Semantics(
        label: 'Selected location information',
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location icon and address
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Location',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _isMapMoving ? 'Moving...' : _addressText,
                                key: ValueKey(
                                  _isMapMoving ? 'moving' : _addressText,
                                ),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _isMapMoving
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Confirm button
                  Semantics(
                    button: true,
                    label: 'Confirm selected location',
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null
                          ? _confirmLocation
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: _selectedLocation != null
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm Location',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _selectedLocation != null
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationFab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 200), // Above bottom card
      child: Semantics(
        button: true,
        label: 'Go to current location',
        child: FloatingActionButton(
          heroTag: 'currentLocation',
          onPressed: _goToCurrentLocation,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          elevation: 4,
          child: const Icon(Icons.my_location_rounded),
        ),
      ),
    );
  }
}

/// Custom animated builder widget for pin animations
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

/// Wrapper for AnimatedBuilder to avoid naming conflict
class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
