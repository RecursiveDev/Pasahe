import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../models/accuracy_level.dart';
import '../../models/fare_result.dart';
import '../../models/route_result.dart';
import '../../models/transport_mode.dart';


/// A modern, accessible fare result card widget.
///
/// Displays transport mode, fare information, and status indicators
/// following Material 3 design guidelines with Jeepney-inspired theming.
class FareResultCard extends StatelessWidget {
  final String transportMode;
  final double fare;
  final IndicatorLevel indicatorLevel;
  final bool isRecommended;
  final int passengerCount;
  final double totalFare;
  final AccuracyLevel accuracy;
  final RouteSource routeSource;
  final double? distanceKm;
  final int? estimatedMinutes;
  final String? discountLabel;
  final VoidCallback? onTap;

  const FareResultCard({
    super.key,
    required this.transportMode,
    required this.fare,
    required this.indicatorLevel,
    this.isRecommended = false,
    this.passengerCount = 1,
    required this.totalFare,
    this.accuracy = AccuracyLevel.precise,
    this.routeSource = RouteSource.osrm,
    this.distanceKm,
    this.estimatedMinutes,
    this.discountLabel,
    this.onTap,
  });


  /// Returns the status color based on indicator level.
  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transitColors = Theme.of(context).extension<TransitColors>();
    switch (indicatorLevel) {
      case IndicatorLevel.standard:
        return transitColors?.standardFare ?? colorScheme.primary;
      case IndicatorLevel.peak:
        return colorScheme.secondary; // Yellow from theme
      case IndicatorLevel.touristTrap:
        return colorScheme.tertiary; // Red from theme
    }
  }

  /// Returns the transport mode icon.
  IconData _getTransportIcon() {
    switch (transportMode.toLowerCase()) {
      case 'jeepney':
        return Icons.directions_bus;
      case 'bus':
        return Icons.directions_bus_filled;
      case 'taxi':
        return Icons.local_taxi;
      case 'grab':
      case 'grab car':
        return Icons.car_rental;
      case 'tricycle':
        return Icons.electric_rickshaw;
      case 'train':
      case 'mrt':
      case 'lrt':
        return Icons.train;
      case 'ferry':
        return Icons.directions_boat;
      case 'uv express':
        return Icons.airport_shuttle;
      default:
        return Icons.commute;
    }
  }

  /// Returns readable status label.
  String _getStatusLabel() {
    switch (indicatorLevel) {
      case IndicatorLevel.standard:
        return 'Standard fare';
      case IndicatorLevel.peak:
        return 'Peak hours';
      case IndicatorLevel.touristTrap:
        return 'High traffic';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);

    return Semantics(
      label: _buildSemanticLabel(),
      button: onTap != null,
      child: Card(
        elevation: isRecommended ? 4 : 2,
        shadowColor: statusColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: statusColor.withValues(alpha: 0.1),
          highlightColor: statusColor.withValues(alpha: 0.05),
          child: Stack(
            children: [
              // Main content with left status bar
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left status indicator bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    // Main content area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Transport mode icon in circular container
                            _buildTransportIcon(context, statusColor),
                            const SizedBox(width: 16),
                            // Info section
                            Expanded(
                              child: _buildInfoSection(context, statusColor),
                            ),
                            const SizedBox(width: 12),
                            // Price section
                            _buildPriceSection(context, statusColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Recommended badge (top right, overlapping)
              if (isRecommended) _buildRecommendedBadge(context),
              // Discount indicator (bottom left)
              if (discountLabel != null) _buildDiscountBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the semantic label for accessibility.
  String _buildSemanticLabel() {
    final buffer = StringBuffer();
    buffer.write('Fare estimate for $transportMode is ');
    buffer.write('${totalFare.toStringAsFixed(2)} pesos');

    if (passengerCount > 1) {
      buffer.write(' for $passengerCount passengers');
    }

    buffer.write('. ${_getStatusLabel()}');

    if (distanceKm != null) {
      buffer.write('. Distance: ${distanceKm!.toStringAsFixed(1)} kilometers');
    }

    if (estimatedMinutes != null) {
      buffer.write('. Estimated time: $estimatedMinutes minutes');
    }

    if (isRecommended) {
      buffer.write('. Best Value option');
    }

    if (discountLabel != null) {
      buffer.write('. Discount: $discountLabel');
    }

    return buffer.toString();
  }

  /// Builds a styled chip for the route source.
  Widget _buildRouteSourceBadge(BuildContext context, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        routeSource.description,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// Builds the accuracy indicator.
  Widget _buildAccuracyIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accuracy.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accuracy.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            accuracy.icon,
            size: 14,
            color: accuracy.color,
          ),
          const SizedBox(width: 4),
          Text(
            accuracy.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accuracy.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  /// Builds the circular transport icon container.

  Widget _buildTransportIcon(BuildContext context, Color statusColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(_getTransportIcon(), color: statusColor, size: 24),
    );
  }

  /// Builds the info section with mode name and details.
  Widget _buildInfoSection(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Parse transport mode to extract base name and subtype
    final parsed = TransportMode.parseTransportMode(transportMode);
    final baseName = parsed.baseName;
    final subtype = parsed.subtype;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transport mode name with optional subtype chip
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              baseName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtype != null)
              _buildSubtypeChip(context, subtype, statusColor),
            _buildRouteSourceBadge(context, statusColor),
          ],
        ),
        const SizedBox(height: 8),
        // Accuracy indicator
        _buildAccuracyIndicator(context),
        const SizedBox(height: 8),
        // Distance and time info row

        Row(
          children: [
            if (distanceKm != null) ...[
              Icon(
                Icons.straighten,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${distanceKm!.toStringAsFixed(1)} km',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (estimatedMinutes != null) ...[
              Icon(
                Icons.schedule,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$estimatedMinutes min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (distanceKm == null && estimatedMinutes == null)
              Text(
                _getStatusLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        // Passenger count info
        if (passengerCount > 1) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$passengerCount passengers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  /// Builds a styled chip/tag for the transport subtype.
  Widget _buildSubtypeChip(BuildContext context, String subtype, Color statusColor) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        subtype,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Builds the price display section.
  Widget _buildPriceSection(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate per-person fare: total divided by passenger count
    // Guard against division by zero (should not happen, but be safe)
    final perPersonFare = passengerCount > 0 ? totalFare / passengerCount : totalFare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Currency symbol and amount
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '₱',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: totalFare.toStringAsFixed(2),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Per person fare if multiple passengers
        if (passengerCount > 1) ...[
          const SizedBox(height: 2),
          Text(
            '₱${perPersonFare.toStringAsFixed(2)}/pax',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the recommended badge.
  Widget _buildRecommendedBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      right: 12,
      child: Transform.translate(
        offset: const Offset(0, -4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.secondary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: colorScheme.onSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Best Value',
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the discount badge.
  Widget _buildDiscountBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 8,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.discount_outlined, size: 12, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              discountLabel!,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
