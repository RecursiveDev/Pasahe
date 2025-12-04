import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../l10n/app_localizations.dart';
import '../../models/discount_type.dart';
import '../../models/fare_formula.dart';
import '../../models/transport_mode.dart';
import '../../repositories/fare_repository.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService? settingsService;

  const SettingsScreen({super.key, this.settingsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;
  late final FareRepository _fareRepository;
  bool _isProvincialModeEnabled = false;
  bool _isHighContrastEnabled = false;
  TrafficFactor _trafficFactor = TrafficFactor.medium;
  DiscountType _discountType = DiscountType.standard;
  bool _isLoading = true;

  Set<String> _hiddenTransportModes = {};
  Map<String, List<FareFormula>> _groupedFormulas = {};

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? getIt<SettingsService>();
    _fareRepository = getIt<FareRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provincialMode = await _settingsService.getProvincialMode();
    final trafficFactor = await _settingsService.getTrafficFactor();
    final highContrast = await _settingsService.getHighContrastEnabled();
    final discountType = await _settingsService.getUserDiscountType();
    final hiddenModes = await _settingsService.getHiddenTransportModes();
    final formulas = await _fareRepository.getAllFormulas();

    // Group formulas by mode
    final grouped = <String, List<FareFormula>>{};
    for (final formula in formulas) {
      if (!grouped.containsKey(formula.mode)) {
        grouped[formula.mode] = [];
      }
      grouped[formula.mode]!.add(formula);
    }

    if (mounted) {
      setState(() {
        _isProvincialModeEnabled = provincialMode;
        _isHighContrastEnabled = highContrast;
        _trafficFactor = trafficFactor;
        _discountType = discountType;
        _hiddenTransportModes = hiddenModes;
        _groupedFormulas = grouped;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.provincialModeTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.provincialModeSubtitle,
                  ),
                  value: _isProvincialModeEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isProvincialModeEnabled = value;
                    });
                    await _settingsService.setProvincialMode(value);
                  },
                ),
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.highContrastModeTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.highContrastModeSubtitle,
                  ),
                  value: _isHighContrastEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isHighContrastEnabled = value;
                    });
                    await _settingsService.setHighContrastEnabled(value);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.trafficFactorTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.trafficFactorSubtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                // ignore: deprecated_member_use
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficLow),
                  subtitle: Text(
                    AppLocalizations.of(context)!.trafficLowSubtitle,
                  ),
                  value: TrafficFactor.low,
                  // ignore: deprecated_member_use
                  groupValue: _trafficFactor,
                  // ignore: deprecated_member_use
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                // ignore: deprecated_member_use
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficMedium),
                  subtitle: Text(
                    AppLocalizations.of(context)!.trafficMediumSubtitle,
                  ),
                  value: TrafficFactor.medium,
                  // ignore: deprecated_member_use
                  groupValue: _trafficFactor,
                  // ignore: deprecated_member_use
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                // ignore: deprecated_member_use
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficHigh),
                  subtitle: Text(
                    AppLocalizations.of(context)!.trafficHighSubtitle,
                  ),
                  value: TrafficFactor.high,
                  // ignore: deprecated_member_use
                  groupValue: _trafficFactor,
                  // ignore: deprecated_member_use
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Passenger Type',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Select your passenger type to apply eligible discounts (20% off for Student, Senior, PWD)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                // ignore: deprecated_member_use
                RadioListTile<DiscountType>(
                  title: Text(DiscountType.standard.displayName),
                  subtitle: const Text('No discount'),
                  value: DiscountType.standard,
                  // ignore: deprecated_member_use
                  groupValue: _discountType,
                  // ignore: deprecated_member_use
                  onChanged: (DiscountType? value) async {
                    if (value != null) {
                      setState(() {
                        _discountType = value;
                      });
                      await _settingsService.setUserDiscountType(value);
                    }
                  },
                ),
                // ignore: deprecated_member_use
                RadioListTile<DiscountType>(
                  title: Text(DiscountType.discounted.displayName),
                  subtitle: const Text(
                    '20% discount (RA 11314, RA 9994, RA 7277)',
                  ),
                  value: DiscountType.discounted,
                  // ignore: deprecated_member_use
                  groupValue: _discountType,
                  // ignore: deprecated_member_use
                  onChanged: (DiscountType? value) async {
                    if (value != null) {
                      setState(() {
                        _discountType = value;
                      });
                      await _settingsService.setUserDiscountType(value);
                    }
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Transport Modes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Select which transport modes to include in fare calculations',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                if (_groupedFormulas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No transport modes available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ..._buildCategorizedTransportModes(),
              ],
            ),
    );
  }

  List<Widget> _buildCategorizedTransportModes() {
    final widgets = <Widget>[];

    // Group modes by category
    final categorizedModes = <String, List<String>>{
      'Road': [],
      'Rail': [],
      'Water': [],
    };

    for (final modeStr in _groupedFormulas.keys) {
      try {
        final mode = TransportMode.fromString(modeStr);
        final category = mode.category;

        // Capitalize category for display
        final categoryKey = category[0].toUpperCase() + category.substring(1);

        if (categorizedModes.containsKey(categoryKey)) {
          categorizedModes[categoryKey]!.add(modeStr);
        }
      } catch (e) {
        // Skip invalid modes
        continue;
      }
    }

    // Build UI for each category
    for (final category in ['Road', 'Rail', 'Water']) {
      final modesInCategory = categorizedModes[category] ?? [];
      if (modesInCategory.isEmpty) continue;

      // Category Header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            children: [
              Icon(
                _getIconForCategory(category),
                size: 20,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      );

      // Transport Mode Cards for this category
      for (final modeStr in modesInCategory) {
        try {
          final mode = TransportMode.fromString(modeStr);
          final formulas = _groupedFormulas[modeStr] ?? [];

          widgets.add(_buildTransportModeCard(mode, formulas));
        } catch (e) {
          continue;
        }
      }
    }

    return widgets;
  }

  Widget _buildTransportModeCard(
    TransportMode mode,
    List<FareFormula> formulas,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Header with Icon and Name
            Row(
              children: [
                Icon(_getIconForMode(mode), size: 24, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mode.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              mode.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),

            if (formulas.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),

              // Subtype Toggles using SwitchListTile for test compatibility
              ...formulas.map((formula) {
                final modeSubTypeKey = '${formula.mode}::${formula.subType}';
                final isHidden = _hiddenTransportModes.contains(modeSubTypeKey);

                return SwitchListTile(
                  title: Text('  ${formula.subType}'),
                  subtitle: formula.notes != null && formula.notes!.isNotEmpty
                      ? Text(
                          '  ${formula.notes}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  value: !isHidden,
                  onChanged: (bool value) async {
                    final shouldHide = !value;
                    await _settingsService.toggleTransportMode(
                      modeSubTypeKey,
                      shouldHide,
                    );

                    setState(() {
                      if (shouldHide) {
                        _hiddenTransportModes.add(modeSubTypeKey);
                      } else {
                        _hiddenTransportModes.remove(modeSubTypeKey);
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.directions_car;
      case 'rail':
        return Icons.train;
      case 'water':
        return Icons.directions_boat;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getIconForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus;
      case TransportMode.bus:
        return Icons.airport_shuttle;
      case TransportMode.taxi:
        return Icons.local_taxi;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.ferry:
        return Icons.directions_boat;
      case TransportMode.tricycle:
        return Icons.pedal_bike;
      case TransportMode.uvExpress:
        return Icons.local_shipping;
      case TransportMode.van:
        return Icons.airport_shuttle;
      case TransportMode.motorcycle:
        return Icons.two_wheeler;
      case TransportMode.edsaCarousel:
        return Icons.directions_bus_filled;
      case TransportMode.pedicab:
        return Icons.directions_bike;
      case TransportMode.kuliglig:
        return Icons.agriculture;
    }
  }
}
