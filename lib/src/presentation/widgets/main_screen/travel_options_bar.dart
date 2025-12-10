import 'package:flutter/material.dart';

import '../../../services/fare_comparison_service.dart';

/// A horizontal scrollable bar displaying travel options like passenger count,
/// discount indicator, and sort criteria.
class TravelOptionsBar extends StatelessWidget {
  final int regularPassengers;
  final int discountedPassengers;
  final SortCriteria sortCriteria;
  final VoidCallback onPassengerTap;
  final ValueChanged<SortCriteria> onSortChanged;

  const TravelOptionsBar({
    super.key,
    required this.regularPassengers,
    required this.discountedPassengers,
    required this.sortCriteria,
    required this.onPassengerTap,
    required this.onSortChanged,
  });

  int get totalPassengers => regularPassengers + discountedPassengers;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Passenger Count Chip
          Semantics(
            label: 'Passenger count: $totalPassengers. Tap to change.',
            button: true,
            child: ActionChip(
              avatar: Icon(
                Icons.people_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                '$totalPassengers Passenger${totalPassengers > 1 ? 's' : ''}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerLowest,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: onPassengerTap,
            ),
          ),
          const SizedBox(width: 8),
          // Discount indicator if applicable
          if (discountedPassengers > 0)
            Chip(
              avatar: Icon(
                Icons.discount_outlined,
                size: 16,
                color: colorScheme.secondary,
              ),
              label: Text(
                '$discountedPassengers Discounted',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          const SizedBox(width: 8),
          // Sort Chip
          Semantics(
            label:
                'Sort by: ${sortCriteria == SortCriteria.priceAsc ? 'Price Low to High' : 'Price High to Low'}',
            button: true,
            child: ActionChip(
              avatar: Icon(
                Icons.sort,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              label: Text(
                sortCriteria == SortCriteria.priceAsc ? 'Lowest' : 'Highest',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerLowest,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                final newCriteria = sortCriteria == SortCriteria.priceAsc
                    ? SortCriteria.priceDesc
                    : SortCriteria.priceAsc;
                onSortChanged(newCriteria);
              },
            ),
          ),
        ],
      ),
    );
  }
}
