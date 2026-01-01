import 'package:flutter/material.dart';

import '../../../models/fare_result.dart';
import '../../../models/transport_mode.dart';
import '../../../core/constants/transport_icons.dart';
import '../../../core/constants/transport_icon_style.dart';
import '../../../services/fare_comparison_service.dart';
import '../fare_result_card.dart';

/// A widget that displays fare results.
/// 
/// When [sortCriteria] is [SortCriteria.lowestOverall], results are displayed
/// as a flat list sorted by price (lowest first) without category headers.
/// For other sort criteria, results are grouped by transport mode category.
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
    // For "Lowest Overall" sort, display a flat list without mode grouping
    if (sortCriteria == SortCriteria.lowestOverall) {
      return _buildFlatList(context);
    }
    
    // For other sort criteria, display grouped by transport mode
    return _buildGroupedList(context);
  }

  /// Builds a flat list of fare results sorted by price (lowest first).
  /// No category headers - just a simple sorted list.
  Widget _buildFlatList(BuildContext context) {
    // Sort fare results by total fare ascending
    final sortedFares = List<FareResult>.from(fareResults)
      ..sort((a, b) => a.totalFare.compareTo(b.totalFare));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedFares.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 200 + (index * 50)),
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FareResultCard(
              transportMode: result.transportMode,
              fare: result.fare,
              indicatorLevel: result.indicatorLevel,
              isRecommended: result.isRecommended,
              passengerCount: result.passengerCount,
              totalFare: result.totalFare,
              accuracy: result.accuracy,
              routeSource: result.routeSource,
              // Show base name + subtype chip (consistent across views)

            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds a grouped list of fare results organized by transport mode.
  Widget _buildGroupedList(BuildContext context) {
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
                    fare: result.fare,
                    indicatorLevel: result.indicatorLevel,
                    isRecommended: result.isRecommended,
                    passengerCount: result.passengerCount,
                    totalFare: result.totalFare,
                    accuracy: result.accuracy,
                    routeSource: result.routeSource,
                    // Show base name + subtype chip (consistent with flat list)
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
            child: TransportIconService.getIconWidget(
              mode,
              color: colorScheme.primary,
              size: 20,
              style: TransportIconStyle.rounded,
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
}

