import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Header widget for fare results section with save route button.
class FareResultsHeader extends StatelessWidget {
  final VoidCallback onSaveRoute;

  const FareResultsHeader({super.key, required this.onSaveRoute});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Fare Options',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Semantics(
          label: 'Save this route for later',
          button: true,
          child: TextButton.icon(
            onPressed: onSaveRoute,
            icon: Icon(
              Icons.bookmark_add_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            label: Text(
              AppLocalizations.of(context)!.saveRouteButton,
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
