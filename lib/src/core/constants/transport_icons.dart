import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/transport_mode.dart';
import './transport_icon_style.dart';

/// A centralized service for retrieving transport mode icons.
///
/// This service provides a clean API for accessing icons across the application,
/// ensuring consistent icon usage and easy maintenance.
///
/// Usage:
/// ```dart
/// // Get default icon for a transport mode
/// final icon = TransportIconService.getIcon(TransportMode.jeepney);
///
/// // Get specific style variant
/// final roundedIcon = TransportIconService.getIconWithStyle(
///   TransportMode.bus,
///   style: TransportIconStyle.rounded,
/// );
///
/// // Get complete Icon widget
/// final iconWidget = TransportIconService.getIconWidget(
///   TransportMode.taxi,
///   size: 32.0,
///   color: Colors.blue,
/// );
/// ```
class TransportIconService {
  // ===========================================================================
  // CONSTANTS - PRIMARY ICONS (No duplicates across modes)
  // ===========================================================================

  /// Primary icon mapping for each transport mode.
  /// Each icon is unique to its transport mode.
  static const Map<TransportMode, IconData> _primaryIcons = {
    TransportMode.jeepney: Icons.directions_bus,
    TransportMode.bus: Icons.directions_bus_filled,
    TransportMode.taxi: Icons.local_taxi,
    TransportMode.train: Icons.train,
    TransportMode.ferry: Icons.directions_boat,
    TransportMode.tricycle: Icons.electric_rickshaw,
    TransportMode.uvExpress: Icons.local_shipping,
    TransportMode.van: Icons.airport_shuttle,
    TransportMode.motorcycle: Icons.two_wheeler,
    TransportMode.edsaCarousel: Icons.directions_bus_rounded,
    TransportMode.pedicab: Icons.pedal_bike,
    TransportMode.kuliglig: Icons.agriculture,
  };

  // ===========================================================================
  // CONSTANTS - SECONDARY/FALLBACK ICONS
  // ===========================================================================

  /// Fallback icon mapping when primary icons are unavailable.
  static const Map<TransportMode, IconData> _fallbackIcons = {
    TransportMode.jeepney: Icons.commute,
    TransportMode.bus: Icons.directions_car,
    TransportMode.taxi: Icons.car_rental,
    TransportMode.train: Icons.tram,
    TransportMode.ferry: Icons.directions_boat_filled,
    TransportMode.tricycle: Icons.two_wheeler,
    TransportMode.uvExpress: Icons.airport_shuttle,
    TransportMode.van: Icons.local_shipping,
    TransportMode.motorcycle: Icons.electric_rickshaw,
    TransportMode.edsaCarousel: Icons.directions_bus,
    TransportMode.pedicab: Icons.directions_bike,
    TransportMode.kuliglig: Icons.pedal_bike,
  };

  // ===========================================================================
  // STYLE VARIANT MAPPING
  // ===========================================================================

  /// Maps transport modes to their available style variants.
  static const Map<TransportMode, Map<TransportIconStyle, IconData>> _styleVariants = {
    TransportMode.jeepney: {
      TransportIconStyle.filled: Icons.directions_bus,
      TransportIconStyle.rounded: Icons.directions_bus_rounded,
      TransportIconStyle.outlined: Icons.directions_bus_outlined,
      TransportIconStyle.sharp: Icons.directions_bus_sharp,
    },
    TransportMode.bus: {
      TransportIconStyle.filled: Icons.directions_bus_filled,
      TransportIconStyle.rounded: Icons.directions_bus_rounded,
      TransportIconStyle.outlined: Icons.directions_bus_outlined,
      TransportIconStyle.sharp: Icons.directions_bus_sharp,
    },
    TransportMode.taxi: {
      TransportIconStyle.filled: Icons.local_taxi,
      TransportIconStyle.rounded: Icons.local_taxi_rounded,
      TransportIconStyle.outlined: Icons.local_taxi_outlined,
      TransportIconStyle.sharp: Icons.local_taxi_sharp,
    },
    TransportMode.train: {
      TransportIconStyle.filled: Icons.train,
      TransportIconStyle.rounded: Icons.train_rounded,
      TransportIconStyle.outlined: Icons.train_outlined,
      TransportIconStyle.sharp: Icons.train_sharp,
    },
    TransportMode.ferry: {
      TransportIconStyle.filled: Icons.directions_boat,
      TransportIconStyle.rounded: Icons.directions_boat_rounded,
      TransportIconStyle.outlined: Icons.directions_boat_outlined,
      TransportIconStyle.sharp: Icons.directions_boat_sharp,
    },
    TransportMode.tricycle: {
      TransportIconStyle.filled: Icons.electric_rickshaw,
      TransportIconStyle.rounded: Icons.electric_rickshaw,
      TransportIconStyle.outlined: Icons.electric_rickshaw,
      TransportIconStyle.sharp: Icons.electric_rickshaw,
    },
    TransportMode.uvExpress: {
      TransportIconStyle.filled: Icons.local_shipping,
      TransportIconStyle.rounded: Icons.local_shipping_rounded,
      TransportIconStyle.outlined: Icons.local_shipping_outlined,
      TransportIconStyle.sharp: Icons.local_shipping_sharp,
    },
    TransportMode.van: {
      TransportIconStyle.filled: Icons.airport_shuttle,
      TransportIconStyle.rounded: Icons.airport_shuttle_rounded,
      TransportIconStyle.outlined: Icons.airport_shuttle_outlined,
      TransportIconStyle.sharp: Icons.airport_shuttle_sharp,
    },
    TransportMode.motorcycle: {
      TransportIconStyle.filled: Icons.two_wheeler,
      TransportIconStyle.rounded: Icons.two_wheeler_rounded,
      TransportIconStyle.outlined: Icons.two_wheeler_outlined,
      TransportIconStyle.sharp: Icons.two_wheeler_sharp,
    },
    TransportMode.edsaCarousel: {
      // Note: Using directions_bus_rounded as the "filled" version for Carousel distinction
      TransportIconStyle.filled: Icons.directions_bus_rounded,
      TransportIconStyle.rounded: Icons.directions_bus_rounded,
      TransportIconStyle.outlined: Icons.directions_bus_outlined,
      TransportIconStyle.sharp: Icons.directions_bus_sharp,
    },
    TransportMode.pedicab: {
      TransportIconStyle.filled: Icons.pedal_bike,
      TransportIconStyle.rounded: Icons.pedal_bike,
      TransportIconStyle.outlined: Icons.pedal_bike,
      TransportIconStyle.sharp: Icons.pedal_bike,
    },
    TransportMode.kuliglig: {
      TransportIconStyle.filled: Icons.agriculture,
      TransportIconStyle.rounded: Icons.agriculture,
      TransportIconStyle.outlined: Icons.agriculture,
      TransportIconStyle.sharp: Icons.agriculture,
    },
  };

  // ===========================================================================
  // PUBLIC API METHODS
  // ===========================================================================

  /// Gets the primary icon for a transport mode.
  ///
  /// This is the recommended method for retrieving icons in most use cases.
  ///
  /// [mode] The transport mode to get the icon for.
  /// [fallbackToSecondary] If true, returns the secondary icon when the primary
  ///   is not available. Defaults to true.
  ///
  /// Returns the primary IconData for the transport mode.
  static IconData getIcon(
    TransportMode mode, {
    bool fallbackToSecondary = true,
  }) {
    final icon = _primaryIcons[mode];
    if (icon != null) {
      return icon;
    }

    if (kDebugMode) {
      debugPrint('TransportIconService: Primary icon not found for $mode. Using fallback.');
    }

    return fallbackToSecondary ? _fallbackIcons[mode] ?? Icons.commute : Icons.commute;
  }

  /// Gets an icon with a specific style variant.
  ///
  /// [mode] The transport mode to get the icon for.
  /// [style] The desired icon style variant. Defaults to [TransportIconStyle.rounded].
  /// [fallbackToDefault] If true, returns the default icon for the mode if the
  ///   requested style is not available. Defaults to true.
  ///
  /// Returns the IconData for the specified style, or a fallback if not available.
  static IconData getIconWithStyle(
    TransportMode mode, {
    TransportIconStyle style = TransportIconStyle.rounded,
    bool fallbackToDefault = true,
  }) {
    final variants = _styleVariants[mode];
    if (variants == null) {
      if (kDebugMode) {
        debugPrint('TransportIconService: No style variants found for $mode.');
      }
      return fallbackToDefault ? getIcon(mode) : Icons.commute;
    }

    final icon = variants[style];
    if (icon != null) {
      return icon;
    }

    if (kDebugMode) {
      debugPrint('TransportIconService: Style $style not found for $mode. Falling back.');
    }

    return fallbackToDefault ? getIcon(mode) : Icons.commute;
  }

  /// Gets the semantic label for a transport mode icon.
  ///
  /// This is useful for accessibility purposes.
  ///
  /// [mode] The transport mode to get the label for.
  ///
  /// Returns a human-readable string describing the icon.
  static String getIconLabel(TransportMode mode) {
    return switch (mode) {
      TransportMode.jeepney => 'Jeepney icon',
      TransportMode.bus => 'Bus icon',
      TransportMode.taxi => 'Taxi icon',
      TransportMode.train => 'Train icon',
      TransportMode.ferry => 'Ferry icon',
      TransportMode.tricycle => 'Tricycle icon',
      TransportMode.uvExpress => 'UV Express icon',
      TransportMode.van => 'Van icon',
      TransportMode.motorcycle => 'Motorcycle icon',
      TransportMode.edsaCarousel => 'EDSA Carousel icon',
      TransportMode.pedicab => 'Pedicab icon',
      TransportMode.kuliglig => 'Kuliglig icon',
    };
  }

  /// Gets all available icons for a transport mode.
  ///
  /// Useful for displaying icon selection UI or testing.
  ///
  /// [mode] The transport mode to get icons for.
  ///
  /// Returns a map of styles to IconData values.
  static Map<TransportIconStyle, IconData> getAllIconsForMode(TransportMode mode) {
    return _styleVariants[mode] ?? {};
  }

  /// Checks if an icon is available for a specific transport mode and style.
  ///
  /// [mode] The transport mode to check.
  /// [style] The icon style to check.
  ///
  /// Returns true if the icon is available for that specific style, false otherwise.
  static bool isIconAvailable(TransportMode mode, {TransportIconStyle style = TransportIconStyle.rounded}) {
    final variants = _styleVariants[mode];
    if (variants == null) return false;
    return variants.containsKey(style);
  }

  /// Gets a Flutter Icon widget with proper semantics.
  ///
  /// This is a convenience method that creates a complete Icon widget.
  ///
  /// [mode] The transport mode for the icon.
  /// [size] The size of the icon. Defaults to 24.0.
  /// [color] The color of the icon. Optional.
  /// [style] The icon style variant. Defaults to [TransportIconStyle.rounded].
  ///
  /// Returns a configured Icon widget.
  static Icon getIconWidget(
    TransportMode mode, {
    double size = 24.0,
    Color? color,
    TransportIconStyle style = TransportIconStyle.rounded,
  }) {
    return Icon(
      getIconWithStyle(mode, style: style),
      size: size,
      color: color,
      semanticLabel: getIconLabel(mode),
    );
  }
}
