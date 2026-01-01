import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/location.dart';

/// A card widget containing origin and destination input fields with autocomplete.
class LocationInputSection extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final bool isLoadingLocation;
  final Future<List<Location>> Function(String query, bool isOrigin)
  onSearchLocations;
  final ValueChanged<Location> onOriginSelected;
  final ValueChanged<Location> onDestinationSelected;
  final VoidCallback onSwapLocations;
  final VoidCallback onUseCurrentLocation;
  final void Function(bool isOrigin) onOpenMapPicker;

  const LocationInputSection({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.isLoadingLocation,
    required this.onSearchLocations,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onSwapLocations,
    required this.onUseCurrentLocation,
    required this.onOpenMapPicker,
  });

  // Fixed dimensions based on InputDecoration contentPadding and text style
  // TextField height ≈ contentPadding.vertical * 2 + text line height ≈ 12*2 + 24 = 48
  // Gap between fields = 12
  // Total height = 48 + 12 + 48 = 108
  // Origin icon center is at 24 (half of first field)
  // Destination icon (16px) center is at 108 - 8 = 100
  // Line should span from below origin circle (24 + 6 = 30) to above destination pin (100 - 8 = 92)
  // Line height = 92 - 30 = 62
  static const double _inputFieldHeight = 48;
  static const double _fieldGap = 12;
  static const double _originCircleSize = 12;
  static const double _destinationIconSize = 16;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Total height of both fields + gap
    const totalFieldsHeight = _inputFieldHeight * 2 + _fieldGap;

    // Calculate line height to connect from origin circle bottom to destination icon top
    // Origin circle center at: _inputFieldHeight / 2 = 24
    // Origin circle bottom at: 24 + 6 = 30
    // Destination icon center at: _inputFieldHeight + _fieldGap + _inputFieldHeight / 2 = 84
    // Destination icon top at: 84 - 8 = 76
    // Line height = 76 - 30 = 46
    const lineHeight = 46.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Indicator - fixed height column with calculated positions
            SizedBox(
              height: totalFieldsHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Spacer to center origin circle with first field
                  SizedBox(height: (_inputFieldHeight - _originCircleSize) / 2),
                  // Origin circle indicator
                  Container(
                    width: _originCircleSize,
                    height: _originCircleSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Connecting line
                  Container(
                    width: 2,
                    height: lineHeight,
                    color: colorScheme.outlineVariant,
                  ),
                  // Destination pin indicator
                  Icon(
                    Icons.location_on,
                    size: _destinationIconSize,
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Input Fields
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _inputFieldHeight,
                    child: _LocationField(
                      label: 'Origin',
                      controller: originController,
                      isOrigin: true,
                      isLoadingLocation: isLoadingLocation,
                      onSearchLocations: (query) =>
                          onSearchLocations(query, true),
                      onLocationSelected: onOriginSelected,
                      onUseCurrentLocation: onUseCurrentLocation,
                      onOpenMapPicker: () => onOpenMapPicker(true),
                    ),
                  ),
                  const SizedBox(height: _fieldGap),
                  SizedBox(
                    height: _inputFieldHeight,
                    child: _LocationField(
                      label: 'Destination',
                      controller: destinationController,
                      isOrigin: false,
                      isLoadingLocation: false,
                      onSearchLocations: (query) =>
                          onSearchLocations(query, false),
                      onLocationSelected: onDestinationSelected,
                      onUseCurrentLocation: null,
                      onOpenMapPicker: () => onOpenMapPicker(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Swap Button - centered vertically relative to both input fields
            SizedBox(
              height: totalFieldsHeight,
              child: Center(
                child: Semantics(
                  label: 'Swap origin and destination',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      color: colorScheme.primary,
                    ),
                    onPressed: onSwapLocations,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal widget for individual location input field with autocomplete.
/// Now a StatefulWidget to track search loading state using ValueNotifier
/// to avoid interfering with Autocomplete's internal state.
class _LocationField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isOrigin;
  final bool isLoadingLocation;
  final Future<List<Location>> Function(String query) onSearchLocations;
  final ValueChanged<Location> onLocationSelected;
  final VoidCallback? onUseCurrentLocation;
  final VoidCallback onOpenMapPicker;

  const _LocationField({
    required this.label,
    required this.controller,
    required this.isOrigin,
    required this.isLoadingLocation,
    required this.onSearchLocations,
    required this.onLocationSelected,
    required this.onUseCurrentLocation,
    required this.onOpenMapPicker,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  final ValueNotifier<bool> _isSearching = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isSearching.dispose();
    super.dispose();
  }

  Future<List<Location>> _handleOptionsBuilder(String query) async {
    if (query.trim().isEmpty) {
      _isSearching.value = false;
      return const <Location>[];
    }

    // Set loading state before fetching
    _isSearching.value = true;

    try {
      final results = await widget.onSearchLocations(query);
      return results;
    } finally {
      // Delay clearing the loading state until after the current frame completes
      // so the autocomplete options have time to render before the spinner disappears.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isSearching.value = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Location>(
          displayStringForOption: (Location option) => option.name,
          initialValue: TextEditingValue(text: widget.controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            return _handleOptionsBuilder(textEditingValue.text);
          },
          onSelected: widget.onLocationSelected,
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Sync controller text
                if (widget.isOrigin &&
                    widget.controller.text != textEditingController.text) {
                  textEditingController.text = widget.controller.text;
                }
                return Semantics(
                  label: 'Input for ${widget.label} location',
                  textField: true,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isSearching,
                    builder: (context, isSearching, child) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: widget.label,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show loading indicator when searching for suggestions
                              if (isSearching)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                )
                              // Show current location loading indicator (origin only)
                              else if (widget.isOrigin &&
                                  widget.isLoadingLocation)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              // Show current location button (origin only)
                              else if (widget.isOrigin &&
                                  widget.onUseCurrentLocation != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'Use my current location',
                                  onPressed: widget.onUseCurrentLocation,
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.map_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                tooltip: 'Select from map',
                                onPressed: widget.onOpenMapPicker,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Location option = options.elementAt(index);
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          option.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
