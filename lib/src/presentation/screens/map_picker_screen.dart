import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../core/errors/failures.dart';
import '../../models/location.dart';
import '../../services/geocoding/geocoding_service.dart';
import '../../services/offline/offline_map_service.dart';
import '../../services/offline/offline_mode_service.dart';

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
  late final GeocodingService _geocodingService;
  late final OfflineModeService _offlineModeService;
  late final OfflineMapService _offlineMapService;
  
  LatLng? _selectedLocation;
  bool _isMapMoving = false;
  bool _isMapAvailable = true;
  final ValueNotifier<bool> _isSearchingLocation = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoadingAddress = ValueNotifier<bool>(false);
  String _addressText = 'Move map to select location';

  /// Debounce timer for reverse geocoding to avoid excessive API calls

  /// during rapid map movements
  Timer? _geocodeDebounceTimer;

  /// Debounce duration for reverse geocoding (400ms)
  static const Duration _geocodeDebounceDuration = Duration(milliseconds: 400);

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
    _geocodingService = getIt<GeocodingService>();
    _offlineModeService = getIt<OfflineModeService>();
    _offlineMapService = getIt<OfflineMapService>();
    
    _selectedLocation = widget.initialLocation ?? _defaultCenter;

    // Listen to offline mode changes
    _offlineModeService.addListener(_onOfflineModeChanged);

    // Initial map availability check
    _checkMapAvailability(_selectedLocation!);

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
    _offlineModeService.removeListener(_onOfflineModeChanged);
    _geocodeDebounceTimer?.cancel();

    _pinAnimationController.dispose();
    _isSearchingLocation.dispose();
    _isLoadingAddress.dispose();
    super.dispose();
  }

  void _onOfflineModeChanged() {
    if (mounted) {
      setState(() {
        // Trigger UI rebuild for offline mode changes
        _updateAddress(_selectedLocation!);
      });
    }
  }

  void _checkMapAvailability(LatLng location) {
    if (!_offlineModeService.isCurrentlyOffline) {
      if (!_isMapAvailable) {
        setState(() => _isMapAvailable = true);
      }
      return;
    }

    final isAvailable = _offlineMapService.isPointCached(location);
    if (isAvailable != _isMapAvailable) {
      setState(() => _isMapAvailable = isAvailable);
    }
  }

  void _handleMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      setState(() => _isMapMoving = true);
      _pinAnimationController.forward();
      // Cancel any pending geocode request when movement starts
      _geocodeDebounceTimer?.cancel();
    } else if (event is MapEventMoveEnd) {
      final center = _mapController.camera.center;
      setState(() {
        _isMapMoving = false;
        _selectedLocation = center;
      });
      _pinAnimationController.reverse();
      _checkMapAvailability(center);
      _debouncedUpdateAddress(center);
    } else if (event is MapEventMove) {
      // Update position during movement
      final center = _mapController.camera.center;
      setState(() {
        _selectedLocation = center;
      });
    }
  }

  /// Debounced reverse geocoding to reduce API calls during rapid map movements.

  /// Cancels any pending request and schedules a new one after the debounce period.
  void _debouncedUpdateAddress(LatLng location) {
    // Cancel any existing pending request
    _geocodeDebounceTimer?.cancel();

    // Show loading indicator immediately for better UX
    _isLoadingAddress.value = true;

    // Schedule the actual geocoding after the debounce period
    _geocodeDebounceTimer = Timer(_geocodeDebounceDuration, () {
      _updateAddress(location);
    });
  }

  void _updateAddress(LatLng location) async {
    // Perform reverse geocoding to get the human-readable address
    _isLoadingAddress.value = true;

    try {
      final address = await _geocodingService.getAddressFromLatLng(
        location.latitude,
        location.longitude,
      );
      if (mounted) {
        setState(() {
          _addressText = address.name;
        });
      }
    } catch (e) {
      // Fallback to coordinates if geocoding fails
      if (mounted) {
        setState(() {
          _addressText =
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } finally {
      _isLoadingAddress.value = false;
    }
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
    _checkMapAvailability(_defaultCenter);
    _updateAddress(_defaultCenter);
  }

  Future<List<Location>> _searchLocations(String query) async {

    if (query.trim().isEmpty) {
      _isSearchingLocation.value = false;
      return [];
    }

    // Set loading state before fetching
    _isSearchingLocation.value = true;

    try {
      final results = await _geocodingService.getLocations(query);
      return results;
    } on Failure {
      // Handle failures gracefully - return empty list
      return [];
    } catch (_) {
      // Handle unexpected errors gracefully
      return [];
    } finally {
      // Clear loading state after fetching
      _isSearchingLocation.value = false;
    }
  }

  void _onLocationSelected(Location location) {
    final newLatLng = LatLng(location.latitude, location.longitude);
    _mapController.move(newLatLng, 15.0);
    setState(() {
      _selectedLocation = newLatLng;
      _addressText = location.name;
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

          // Map availability warning (only when offline)
          if (_offlineModeService.isCurrentlyOffline && !_isMapAvailable)
            _buildMapAvailabilityWarning(theme, colorScheme),

          // Floating search bar at top (hidden in offline mode)
          if (!_offlineModeService.isCurrentlyOffline)
            _buildFloatingSearchBar(theme, colorScheme),

          // Offline indicator badge (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            right: 16,
            child: const OfflineIndicatorBadge(),
          ),

          // Offline help text (if offline)
          if (_offlineModeService.isCurrentlyOffline)
            _buildOfflineHelpText(theme, colorScheme),

          // Bottom location card
          _buildBottomLocationCard(theme, colorScheme),
        ],
      ),
      // Current location FAB

      floatingActionButton: _buildCurrentLocationFab(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMapAvailabilityWarning(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Map not available offline here. Please move to a cached region.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineHelpText(ThemeData theme, ColorScheme colorScheme) {
    return Positioned(
      bottom: 250, // Above current location FAB
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Offline Mode: Drag map to select coordinates',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
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
  /// The tile style automatically adjusts based on the current theme (light/dark).
  /// For dark mode, CartoDB Voyager tiles are inverted using ColorFiltered.
  Widget _buildTileLayer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget tileLayer;

    try {
      final offlineMapService = getIt<OfflineMapService>();
      final offlineModeService = getIt<OfflineModeService>();
      tileLayer = offlineMapService.getThemedCachedTileLayer(
        isDarkMode: isDarkMode,
        allowDownloads: offlineModeService.shouldAllowDownloads,
      );
    } catch (_) {

      // Fall back to network tiles if service not initialized
      tileLayer = OfflineMapService.getNetworkTileLayer(isDarkMode: isDarkMode);
    }

    // Apply color inversion for dark mode to create dark appearance from Voyager tiles
    if (isDarkMode) {
      return OfflineMapService.wrapWithDarkModeFilter(tileLayer);
    }

    return tileLayer;
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
              border: Border.all(color: colorScheme.surface, width: 3),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<Location>(
                  displayStringForOption: (Location option) => option.name,
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.trim().isEmpty) {
                      return const Iterable<Location>.empty();
                    }
                    return _searchLocations(textEditingValue.text);
                  },
                  onSelected: _onLocationSelected,
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return AnimatedContainer(
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
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _isSearchingLocation,
                            builder: (context, isSearching, child) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search location...',
                                  hintStyle: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: colorScheme.primary,
                                  ),
                                  suffixIcon: isSearching
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : (focusNode.hasFocus ||
                                            textEditingController
                                                .text
                                                .isNotEmpty)
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () {
                                            textEditingController.clear();
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
                              );
                            },
                          ),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: constraints.maxWidth,
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Location option = options.elementAt(index);
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  option.name,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
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
                              _offlineModeService.isCurrentlyOffline
                                  ? 'Selected Coordinates'
                                  : 'Selected Location',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isLoadingAddress,
                                builder: (context, isLoading, child) {
                                  if (_isMapMoving) {
                                    return Text(
                                      _offlineModeService.isCurrentlyOffline
                                          ? 'Updating...'
                                          : 'Moving...',
                                      key: const ValueKey('moving'),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  } else if (isLoading &&
                                      !_offlineModeService.isCurrentlyOffline) {
                                    return Row(
                                      key: const ValueKey('loading'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Getting address...',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Text(
                                      _addressText,
                                      key: ValueKey(_addressText),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _offlineModeService.isCurrentlyOffline
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                        fontFamily:
                                            _offlineModeService.isCurrentlyOffline
                                                ? 'monospace'
                                                : null,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                },
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
    // Only show current location FAB if we are online OR if current location might be cached
    // For simplicity, we show it and let the user see if it's cached
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
