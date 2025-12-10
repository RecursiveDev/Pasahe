import 'package:flutter/material.dart';

import '../../../models/fare_result.dart';
import '../../../models/transport_mode.dart';
import '../../../services/fare_comparison_service.dart';
import '../fare_result_card.dart';

/// A widget that displays grouped fare results by transport mode.
class FareResultsList extends StatelessWidget {
  final List<FareResult> fareResults;
  final SortCriteria sortCriteria;
  final FareComparisonService fareComparisonService;

  const FareResultsList({
    super.key,
    required this.fareResults,
    required this.sortCriteria,
    required this.fareComparisonService,
  });

  @override
  Widget build(BuildContext context) {
    final groupedResults = fareComparisonService.groupFaresByMode(fareResults);
    final sortedGroups = groupedResults.entries.toList();

    if (sortCriteria == SortCriteria.priceAsc) {
      sortedGroups.sort((a, b) {
        final aMin = a.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a < b ? a : b);
        final bMin = b.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a < b ? a : b);
        return aMin.compareTo(bMin);
      });
    } else if (sortCriteria == SortCriteria.priceDesc) {
      sortedGroups.sort((a, b) {
        final aMax = a.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a > b ? a : b);
        final bMax = b.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a > b ? a : b);
        return bMax.compareTo(aMax);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedGroups.asMap().entries.map((entry) {
        final index = entry.key;
        final groupEntry = entry.value;
        final mode = groupEntry.key;
        final fares = groupEntry.value;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TransportModeHeader(mode: mode),
              const SizedBox(height: 8),
              ...fares.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FareResultCard(
                    transportMode: result.transportMode,
                    fare: result.totalFare,
                    indicatorLevel: result.indicatorLevel,
                    isRecommended: result.isRecommended,
                    passengerCount: result.passengerCount,
                    totalFare: result.totalFare,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Header widget for transport mode sections.
class _TransportModeHeader extends StatelessWidget {
  final TransportMode mode;

  const _TransportModeHeader({required this.mode});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransportModeIcon(mode),
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            mode.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus;
      case TransportMode.bus:
        return Icons.directions_bus_filled;
      case TransportMode.taxi:
        return Icons.local_taxi;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.ferry:
        return Icons.directions_boat;
      case TransportMode.tricycle:
        return Icons.electric_rickshaw;
      case TransportMode.uvExpress:
        return Icons.airport_shuttle;
      case TransportMode.van:
        return Icons.airport_shuttle;
      case TransportMode.motorcycle:
        return Icons.two_wheeler;
      case TransportMode.edsaCarousel:
        return Icons.directions_bus;
      case TransportMode.pedicab:
        return Icons.pedal_bike;
      case TransportMode.kuliglig:
        return Icons.agriculture;
    }
  }
}
