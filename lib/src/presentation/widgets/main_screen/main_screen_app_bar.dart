import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/offline/offline_mode_service.dart';
import '../../screens/offline_menu_screen.dart';
import '../../screens/settings_screen.dart';
import '../app_logo_widget.dart';


/// Modern app bar widget for the main screen.
class MainScreenAppBar extends StatelessWidget {
  const MainScreenAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const AppLogoWidget(size: AppLogoSize.small, showShadow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.fareEstimatorTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where are you going today?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: getIt<OfflineModeService>(),
            builder: (context, child) {
              final offlineService = getIt<OfflineModeService>();
              final isEnabled = offlineService.offlineModeEnabled;
              return Semantics(
                label: 'Toggle offline mode',
                button: true,
                child: IconButton(
                  icon: Icon(
                    isEnabled
                        ? Icons.offline_bolt_rounded
                        : Icons.offline_bolt_outlined,
                    color: isEnabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isEnabled
                      ? 'Offline Mode Enabled'
                      : 'Enable Offline Mode',
                  onPressed: () {
                    offlineService.setOfflineModeEnabled(!isEnabled);
                  },
                ),
              );
            },
          ),
          Semantics(

            label: 'Open offline reference menu',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Offline Reference',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineMenuScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Open settings',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
