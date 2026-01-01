import 'package:flutter/material.dart';

import '../../../models/fare_formula.dart';
import '../../../models/transport_mode.dart';
import '../../../services/settings_service.dart';

/// A modal bottom sheet that allows users to select which transport modes
/// to enable for fare calculations. This is shown when a new user attempts
/// to calculate fares but has no transport modes enabled.
class TransportModeSelectionModal extends StatefulWidget {
  /// The settings service for saving preferences.
  final SettingsService settingsService;

  /// All available fare formulas to display as options.
  final List<FareFormula> availableFormulas;

  /// Called when user confirms their selection.
  final VoidCallback? onConfirmed;

  /// Called when user cancels the modal.
  final VoidCallback? onCancelled;

  const TransportModeSelectionModal({
    super.key,
    required this.settingsService,
    required this.availableFormulas,
    this.onConfirmed,
    this.onCancelled,
  });

  /// Shows the transport mode selection modal as a bottom sheet.
  /// Returns true if the user confirmed their selection, false otherwise.
  static Future<bool> show({
    required BuildContext context,
    required SettingsService settingsService,
    required List<FareFormula> availableFormulas,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => TransportModeSelectionModal(
        settingsService: settingsService,
        availableFormulas: availableFormulas,
      ),
    );
    return result ?? false;
  }

  @override
  State<TransportModeSelectionModal> createState() =>
      _TransportModeSelectionModalState();
}

class _TransportModeSelectionModalState
    extends State<TransportModeSelectionModal> {
  /// Set of selected mode-subtype keys (format: "Mode::SubType").
  final Set<String> _selectedModes = {};

  /// Grouped formulas by mode.
  late Map<String, List<FareFormula>> _groupedFormulas;

  @override
  void initState() {
    super.initState();
    _groupedFormulas = _groupFormulas();
    _loadSavedPreferences();
  }

  /// Loads saved transport mode preferences and initializes selected modes.
  /// Modes that are NOT in the hidden set should be marked as selected.
  Future<void> _loadSavedPreferences() async {
    final hiddenModes = await widget.settingsService.getHiddenTransportModes();

    setState(() {
      for (final formula in widget.availableFormulas) {
        final modeSubTypeKey = '${formula.mode}::${formula.subType}';
        // Mode is selected if it's NOT hidden
        if (!hiddenModes.contains(modeSubTypeKey)) {
          _selectedModes.add(modeSubTypeKey);
        }
      }
    });
  }

  Map<String, List<FareFormula>> _groupFormulas() {
    final grouped = <String, List<FareFormula>>{};
    for (final formula in widget.availableFormulas) {
      if (!grouped.containsKey(formula.mode)) {
        grouped[formula.mode] = [];
      }
      grouped[formula.mode]!.add(formula);
    }
    return grouped;
  }

  bool get _hasSelection => _selectedModes.isNotEmpty;

  Future<void> _onConfirm() async {
    if (!_hasSelection) return;

    // First, save all selected modes as enabled (not hidden).
    // All other modes remain hidden.
    for (final formula in widget.availableFormulas) {
      final modeSubTypeKey = '${formula.mode}::${formula.subType}';
      final isSelected = _selectedModes.contains(modeSubTypeKey);
      // toggleTransportMode: isHidden=true means hidden, isHidden=false means visible
      await widget.settingsService.toggleTransportMode(
        modeSubTypeKey,
        !isSelected, // If selected, should NOT be hidden (isHidden=false)
      );
    }

    widget.onConfirmed?.call();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onCancel() {
    widget.onCancelled?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    // Calculate max height (80% of screen)
    final maxHeight = mediaQuery.size.height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select Transport Modes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select at least one transport mode to include '
                          'in your fare calculations.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildCategorizedTransportModes(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Bottom action buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _hasSelection ? _onConfirm : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _hasSelection
                                ? 'Apply (${_selectedModes.length})'
                                : 'Select at least one',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedTransportModes() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
        final categoryKey = category[0].toUpperCase() + category.substring(1);

        if (categorizedModes.containsKey(categoryKey)) {
          categorizedModes[categoryKey]!.add(modeStr);
        }
      } catch (e) {
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
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Icon(
                _getIconForCategory(category),
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    _selectAllInCategory(category, modesInCategory),
                icon: Icon(
                  _isAllSelectedInCategory(modesInCategory)
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  size: 18,
                ),
                label: Text(
                  _isAllSelectedInCategory(modesInCategory)
                      ? 'Deselect'
                      : 'Select All',
                  style: theme.textTheme.labelSmall,
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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

          widgets.add(_buildTransportModeSection(mode, formulas));
        } catch (e) {
          continue;
        }
      }
    }

    return widgets;
  }

  bool _isAllSelectedInCategory(List<String> modesInCategory) {
    for (final modeStr in modesInCategory) {
      final formulas = _groupedFormulas[modeStr] ?? [];
      for (final formula in formulas) {
        final key = '${formula.mode}::${formula.subType}';
        if (!_selectedModes.contains(key)) {
          return false;
        }
      }
    }
    return true;
  }

  void _selectAllInCategory(String category, List<String> modesInCategory) {
    final allSelected = _isAllSelectedInCategory(modesInCategory);

    setState(() {
      for (final modeStr in modesInCategory) {
        final formulas = _groupedFormulas[modeStr] ?? [];
        for (final formula in formulas) {
          final key = '${formula.mode}::${formula.subType}';
          if (allSelected) {
            _selectedModes.remove(key);
          } else {
            _selectedModes.add(key);
          }
        }
      }
    });
  }

  Widget _buildTransportModeSection(
    TransportMode mode,
    List<FareFormula> formulas,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getIconForMode(mode),
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mode.displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (formulas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),

            // Subtype Checkboxes
            ...formulas.map((formula) {
              final modeSubTypeKey = '${formula.mode}::${formula.subType}';
              final isSelected = _selectedModes.contains(modeSubTypeKey);

              return CheckboxListTile(
                title: Text(
                  formula.subType,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: formula.notes != null && formula.notes!.isNotEmpty
                    ? Text(
                        formula.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedModes.add(modeSubTypeKey);
                    } else {
                      _selectedModes.remove(modeSubTypeKey);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: colorScheme.primary,
                checkColor: colorScheme.onPrimary,
              );
            }),
          ],
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.directions_car_rounded;
      case 'rail':
        return Icons.train_rounded;
      case 'water':
        return Icons.directions_boat_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _getIconForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus_rounded;
      case TransportMode.bus:
        return Icons.airport_shuttle_rounded;
      case TransportMode.taxi:
        return Icons.local_taxi_rounded;
      case TransportMode.train:
        return Icons.train_rounded;
      case TransportMode.ferry:
        return Icons.directions_boat_rounded;
      case TransportMode.tricycle:
        return Icons.pedal_bike_rounded;
      case TransportMode.uvExpress:
        return Icons.local_shipping_rounded;
      case TransportMode.van:
        return Icons.airport_shuttle_rounded;
      case TransportMode.motorcycle:
        return Icons.two_wheeler_rounded;
      case TransportMode.edsaCarousel:
        return Icons.directions_bus_filled_rounded;
      case TransportMode.pedicab:
        return Icons.directions_bike_rounded;
      case TransportMode.kuliglig:
        return Icons.agriculture_rounded;
    }
  }
}
