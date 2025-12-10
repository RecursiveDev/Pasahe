import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Calculate fare button with loading state.
class CalculateFareButton extends StatelessWidget {
  final bool canCalculate;
  final bool isCalculating;
  final VoidCallback? onPressed;

  const CalculateFareButton({
    super.key,
    required this.canCalculate,
    required this.isCalculating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Calculate Fare based on selected origin and destination',
      button: true,
      enabled: canCalculate,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: canCalculate ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: isCalculating
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate_outlined),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.calculateFareButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
