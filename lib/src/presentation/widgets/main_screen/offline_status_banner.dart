import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../models/connectivity_status.dart';
import '../../../services/offline/offline_mode_service.dart';

/// Banner widget for displaying offline/limited connectivity status.
class OfflineStatusBanner extends StatelessWidget {
  final ConnectivityStatus status;

  const OfflineStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final offlineService = getIt<OfflineModeService>();
    final isManualOffline = offlineService.offlineModeEnabled;
    final isOffline = status.isOffline || isManualOffline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline
          ? (isManualOffline
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest)
          : colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(
            isOffline
                ? (isManualOffline ? Icons.offline_bolt : Icons.cloud_off)
                : Icons.signal_wifi_statusbar_4_bar,
            size: 18,
            color: isOffline
                ? (isManualOffline
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface)
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? (isManualOffline
                      ? 'Offline Mode enabled. Using cached data.'
                      : 'You are offline. Showing cached routes.')
                  : 'Limited connectivity. Some features may be unavailable.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOffline
                    ? (isManualOffline
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface)
                    : colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          if (isManualOffline)
            TextButton(
              onPressed: () => offlineService.setOfflineModeEnabled(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Go Online',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

