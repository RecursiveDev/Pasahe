import 'package:flutter/material.dart';

import '../../../models/connectivity_status.dart';

/// Banner widget for displaying offline/limited connectivity status.
class OfflineStatusBanner extends StatelessWidget {
  final ConnectivityStatus status;

  const OfflineStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOffline = status.isOffline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline
          ? colorScheme.surfaceContainerHighest
          : colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.signal_wifi_statusbar_4_bar,
            size: 18,
            color: isOffline
                ? colorScheme.onSurface
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'You are offline. Showing cached routes.'
                  : 'Limited connectivity. Some features may be unavailable.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOffline
                    ? colorScheme.onSurface
                    : colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
