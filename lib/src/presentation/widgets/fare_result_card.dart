import 'package:flutter/material.dart';
import '../../models/fare_result.dart';

class FareResultCard extends StatelessWidget {
  final String transportMode;
  final double fare;
  final IndicatorLevel indicatorLevel;

  const FareResultCard({
    super.key,
    required this.transportMode,
    required this.fare,
    required this.indicatorLevel,
  });

  Color _getColor(IndicatorLevel level) {
    switch (level) {
      case IndicatorLevel.standard:
        return Colors.green;
      case IndicatorLevel.peak:
        return Colors.amber;
      case IndicatorLevel.touristTrap:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(indicatorLevel);

    return Semantics(
      label: 'Fare estimate for $transportMode is ${fare.toStringAsFixed(2)} pesos. Traffic level: ${indicatorLevel.name}.',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: color, width: 2.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                transportMode,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                '₱ ${fare.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}