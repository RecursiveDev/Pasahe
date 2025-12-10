import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/route_result.dart';
import '../map_selection_widget.dart';

/// A widget that displays a map preview with origin, destination, and route.
///
/// Supports displaying both road-following routes (from OSRM) and
/// straight-line fallback routes (from Haversine), with different styling
/// to indicate the route type to users.
class MapPreview extends StatelessWidget {
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final RouteSource? routeSource;
  final double height;
  final bool showRouteInfo;

  const MapPreview({
    super.key,
    this.origin,
    this.destination,
    this.routePoints = const [],
    this.routeSource,
    this.height = 200,
    this.showRouteInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            MapSelectionWidget(
              origin: origin,
              destination: destination,
              routePoints: routePoints,
            ),
            // Overlay gradient for better visibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Route source indicator
            if (showRouteInfo && routeSource != null && routePoints.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: _buildRouteSourceBadge(context),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a badge showing the route source (road-based vs estimated).
  Widget _buildRouteSourceBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isRoadBased = routeSource?.isRoadBased ?? false;
    final icon = isRoadBased ? Icons.route : Icons.straighten;
    final label = isRoadBased ? 'Road route' : 'Estimated';
    final backgroundColor = isRoadBased
        ? colorScheme.primaryContainer
        : colorScheme.tertiaryContainer;
    final foregroundColor = isRoadBased
        ? colorScheme.onPrimaryContainer
        : colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension widget that provides enhanced map preview with route result.
class EnhancedMapPreview extends StatelessWidget {
  final LatLng? origin;
  final LatLng? destination;
  final RouteResult? routeResult;
  final double height;
  final bool showRouteInfo;
  final bool showDistanceInfo;

  const EnhancedMapPreview({
    super.key,
    this.origin,
    this.destination,
    this.routeResult,
    this.height = 200,
    this.showRouteInfo = true,
    this.showDistanceInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            MapSelectionWidget(
              origin: origin,
              destination: destination,
              routePoints: routeResult?.geometry ?? const [],
            ),
            // Overlay gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Route info overlay
            if (showRouteInfo && routeResult != null)
              Positioned(
                top: 8,
                right: 8,
                child: _buildRouteSourceBadge(context),
              ),
            // Distance info overlay
            if (showDistanceInfo && routeResult != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: _buildDistanceInfo(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSourceBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final source = routeResult?.source ?? RouteSource.haversine;
    final isRoadBased = source.isRoadBased;
    final icon = isRoadBased ? Icons.route : Icons.straighten;
    final label = source.description;
    final backgroundColor = isRoadBased
        ? colorScheme.primaryContainer
        : colorScheme.tertiaryContainer;
    final foregroundColor = isRoadBased
        ? colorScheme.onPrimaryContainer
        : colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInfo(BuildContext context) {
    final theme = Theme.of(context);
    final distance = routeResult?.distance ?? 0;
    final duration = routeResult?.duration;

    // Format distance
    String distanceText;
    if (distance >= 1000) {
      distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      distanceText = '${distance.toStringAsFixed(0)} m';
    }

    // Format duration
    String? durationText;
    if (duration != null) {
      final minutes = (duration / 60).round();
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        durationText = '${hours}h ${mins}m';
      } else {
        durationText = '$minutes min';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            distanceText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (durationText != null) ...[
            const SizedBox(width: 12),
            const Icon(Icons.schedule, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              durationText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
