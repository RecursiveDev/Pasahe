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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Indicator
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 48,
                      color: colorScheme.outlineVariant,
                    ),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Input Fields
                Expanded(
                  child: Column(
                    children: [
                      _LocationField(
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
                      const SizedBox(height: 12),
                      _LocationField(
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
                    ],
                  ),
                ),
                // Swap Button
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 20),
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
                        backgroundColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal widget for individual location input field with autocomplete.
class _LocationField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Location>(
          displayStringForOption: (Location option) => option.name,
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.trim().isEmpty) {
              return const Iterable<Location>.empty();
            }
            return onSearchLocations(textEditingValue.text);
          },
          onSelected: onLocationSelected,
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Sync controller text
                if (isOrigin && controller.text != textEditingController.text) {
                  textEditingController.text = controller.text;
                }
                return Semantics(
                  label: 'Input for $label location',
                  textField: true,
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: label,
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
                          if (isOrigin && isLoadingLocation)
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
                          else if (isOrigin && onUseCurrentLocation != null)
                            IconButton(
                              icon: Icon(
                                Icons.my_location,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Use my current location',
                              onPressed: onUseCurrentLocation,
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.map_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            tooltip: 'Select from map',
                            onPressed: onOpenMapPicker,
                          ),
                        ],
                      ),
                    ),
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
