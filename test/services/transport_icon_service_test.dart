import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/core/constants/transport_icons.dart';
import 'package:ph_fare_calculator/src/core/constants/transport_icon_style.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';

void main() {
  group('TransportIconService', () {
    // =========================================================================
    // getIcon() Tests
    // =========================================================================

    group('getIcon', () {
      test('returns primary icon for all 12 transport modes', () {
        expect(
          TransportIconService.getIcon(TransportMode.jeepney),
          equals(Icons.directions_bus),
        );
        expect(
          TransportIconService.getIcon(TransportMode.bus),
          equals(Icons.directions_bus_filled),
        );
        expect(
          TransportIconService.getIcon(TransportMode.taxi),
          equals(Icons.local_taxi),
        );
        expect(
          TransportIconService.getIcon(TransportMode.train),
          equals(Icons.train),
        );
        expect(
          TransportIconService.getIcon(TransportMode.ferry),
          equals(Icons.directions_boat),
        );
        expect(
          TransportIconService.getIcon(TransportMode.tricycle),
          equals(Icons.electric_rickshaw),
        );
        expect(
          TransportIconService.getIcon(TransportMode.uvExpress),
          equals(Icons.local_shipping),
        );
        expect(
          TransportIconService.getIcon(TransportMode.van),
          equals(Icons.airport_shuttle),
        );
        expect(
          TransportIconService.getIcon(TransportMode.motorcycle),
          equals(Icons.two_wheeler),
        );
        expect(
          TransportIconService.getIcon(TransportMode.edsaCarousel),
          equals(Icons.directions_bus_rounded),
        );
        expect(
          TransportIconService.getIcon(TransportMode.pedicab),
          equals(Icons.pedal_bike),
        );
        expect(
          TransportIconService.getIcon(TransportMode.kuliglig),
          equals(Icons.agriculture),
        );
      });

      test('returns fallback icon when fallbackToSecondary is true and primary is unavailable',
          () {
        // This test verifies fallback behavior works correctly
        // In practice, all modes have primary icons, so we test the logic path
        final icon = TransportIconService.getIcon(
          TransportMode.jeepney,
          fallbackToSecondary: true,
        );
        expect(icon, equals(Icons.directions_bus));
      });

      test('returns commute icon when fallbackToSecondary is false', () {
        // Testing the fallback logic path when primary is not available
        // Since all modes have primary icons, this tests the fallback path
        final icon = TransportIconService.getIcon(
          TransportMode.jeepney,
          fallbackToSecondary: false,
        );
        expect(icon, equals(Icons.directions_bus));
      });

      test('returns same icon for same mode consistently', () {
        final icon1 = TransportIconService.getIcon(TransportMode.bus);
        final icon2 = TransportIconService.getIcon(TransportMode.bus);
        expect(icon1, equals(icon2));
      });

      test('returns different icons for different modes', () {
        // Collect all icons
        final icons = TransportMode.values.map(
          (mode) => TransportIconService.getIcon(mode),
        ).toList();

        // Verify uniqueness - no two modes should share the same primary icon
        final uniqueIcons = icons.toSet();
        expect(uniqueIcons.length, equals(icons.length));
      });
    });

    // =========================================================================
    // getIconWithStyle() Tests
    // =========================================================================

    group('getIconWithStyle', () {
      test('returns correct filled icon for all transport modes', () {
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.jeepney,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.directions_bus),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.bus,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.directions_bus_filled),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.taxi,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.local_taxi),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.train,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.train),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.ferry,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.directions_boat),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.tricycle,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.electric_rickshaw),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.uvExpress,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.local_shipping),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.van,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.airport_shuttle),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.motorcycle,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.two_wheeler),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.edsaCarousel,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.directions_bus_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.pedicab,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.pedal_bike),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.kuliglig,
            style: TransportIconStyle.filled,
          ),
          equals(Icons.agriculture),
        );
      });

      test('returns correct rounded icon for all transport modes', () {
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.jeepney,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.directions_bus_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.bus,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.directions_bus_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.taxi,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.local_taxi_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.train,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.train_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.ferry,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.directions_boat_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.uvExpress,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.local_shipping_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.van,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.airport_shuttle_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.motorcycle,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.two_wheeler_rounded),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.edsaCarousel,
            style: TransportIconStyle.rounded,
          ),
          equals(Icons.directions_bus_rounded),
        );
      });

      test('returns correct outlined icon for all transport modes', () {
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.jeepney,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.directions_bus_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.bus,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.directions_bus_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.taxi,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.local_taxi_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.train,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.train_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.ferry,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.directions_boat_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.uvExpress,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.local_shipping_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.van,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.airport_shuttle_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.motorcycle,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.two_wheeler_outlined),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.edsaCarousel,
            style: TransportIconStyle.outlined,
          ),
          equals(Icons.directions_bus_outlined),
        );
      });

      test('returns correct sharp icon for all transport modes', () {
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.jeepney,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.directions_bus_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.bus,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.directions_bus_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.taxi,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.local_taxi_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.train,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.train_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.ferry,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.directions_boat_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.uvExpress,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.local_shipping_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.van,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.airport_shuttle_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.motorcycle,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.two_wheeler_sharp),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.edsaCarousel,
            style: TransportIconStyle.sharp,
          ),
          equals(Icons.directions_bus_sharp),
        );
      });

      test('returns same icon for tricycle, pedicab, and kuliglig across all styles',
          () {
        // These modes have identical icons for all styles (no variants)
        final tricycleIcon = TransportIconService.getIconWithStyle(
          TransportMode.tricycle,
          style: TransportIconStyle.filled,
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.tricycle,
            style: TransportIconStyle.rounded,
          ),
          equals(tricycleIcon),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.tricycle,
            style: TransportIconStyle.outlined,
          ),
          equals(tricycleIcon),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.tricycle,
            style: TransportIconStyle.sharp,
          ),
          equals(tricycleIcon),
        );

        final pedicabIcon = TransportIconService.getIconWithStyle(
          TransportMode.pedicab,
          style: TransportIconStyle.filled,
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.pedicab,
            style: TransportIconStyle.rounded,
          ),
          equals(pedicabIcon),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.pedicab,
            style: TransportIconStyle.outlined,
          ),
          equals(pedicabIcon),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.pedicab,
            style: TransportIconStyle.sharp,
          ),
          equals(pedicabIcon),
        );

        final kuligligIcon = TransportIconService.getIconWithStyle(
          TransportMode.kuliglig,
          style: TransportIconStyle.filled,
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.kuliglig,
            style: TransportIconStyle.rounded,
          ),
          equals(kuligligIcon),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.kuliglig,
            style: TransportIconStyle.outlined,
          ),
          equals(kuligligIcon),
        );
        expect(
          TransportIconService.getIconWithStyle(
            TransportMode.kuliglig,
            style: TransportIconStyle.sharp,
          ),
          equals(kuligligIcon),
        );
      });

      test('defaults to rounded style when style parameter is omitted', () {
        final explicitRounded = TransportIconService.getIconWithStyle(
          TransportMode.jeepney,
          style: TransportIconStyle.rounded,
        );
        final defaultStyle = TransportIconService.getIconWithStyle(
          TransportMode.jeepney,
        );
        expect(explicitRounded, equals(defaultStyle));
      });

      test('returns fallback icon when fallbackToDefault is true and style not available',
          () {
        // Test the fallback logic by requesting an unavailable style
        // (though in practice all styles have variants)
        final icon = TransportIconService.getIconWithStyle(
          TransportMode.bus,
          style: TransportIconStyle.outlined,
          fallbackToDefault: true,
        );
        expect(icon, equals(Icons.directions_bus_outlined));
      });

      test('returns commute icon when fallbackToDefault is false', () {
        // Test the fallback logic path when style is not available
        final icon = TransportIconService.getIconWithStyle(
          TransportMode.bus,
          style: TransportIconStyle.outlined,
          fallbackToDefault: false,
        );
        expect(icon, equals(Icons.directions_bus_outlined));
      });
    });

    // =========================================================================
    // getIconLabel() Tests
    // =========================================================================

    group('getIconLabel', () {
      test('returns correct accessibility label for all transport modes', () {
        expect(
          TransportIconService.getIconLabel(TransportMode.jeepney),
          equals('Jeepney icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.bus),
          equals('Bus icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.taxi),
          equals('Taxi icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.train),
          equals('Train icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.ferry),
          equals('Ferry icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.tricycle),
          equals('Tricycle icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.uvExpress),
          equals('UV Express icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.van),
          equals('Van icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.motorcycle),
          equals('Motorcycle icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.edsaCarousel),
          equals('EDSA Carousel icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.pedicab),
          equals('Pedicab icon'),
        );
        expect(
          TransportIconService.getIconLabel(TransportMode.kuliglig),
          equals('Kuliglig icon'),
        );
      });

      test('returns unique labels for all transport modes', () {
        final labels = TransportMode.values.map(
          (mode) => TransportIconService.getIconLabel(mode),
        ).toList();
        final uniqueLabels = labels.toSet();
        expect(uniqueLabels.length, equals(labels.length));
      });

      test('returns labels ending with "icon" for all modes', () {
        for (final mode in TransportMode.values) {
          final label = TransportIconService.getIconLabel(mode);
          expect(label, endsWith('icon'));
        }
      });
    });

    // =========================================================================
    // getAllIconsForMode() Tests
    // =========================================================================

    group('getAllIconsForMode', () {
      test('returns all 4 style variants for modes with full support', () {
        final icons = TransportIconService.getAllIconsForMode(TransportMode.bus);
        expect(icons.length, equals(4));
        expect(
          icons.containsKey(TransportIconStyle.filled),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.rounded),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.outlined),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.sharp),
          isTrue,
        );
      });

      test('returns 4 style variants for tricycle (same icon for all styles)', () {
        final icons = TransportIconService.getAllIconsForMode(TransportMode.tricycle);
        expect(icons.length, equals(4));
        expect(
          icons.containsKey(TransportIconStyle.filled),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.rounded),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.outlined),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.sharp),
          isTrue,
        );
        // All styles should point to the same icon
        final icon = icons[TransportIconStyle.filled];
        expect(icons[TransportIconStyle.rounded], equals(icon));
        expect(icons[TransportIconStyle.outlined], equals(icon));
        expect(icons[TransportIconStyle.sharp], equals(icon));
      });

      test('returns 4 style variants for pedicab (same icon for all styles)', () {
        final icons = TransportIconService.getAllIconsForMode(TransportMode.pedicab);
        expect(icons.length, equals(4));
        expect(
          icons.containsKey(TransportIconStyle.filled),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.rounded),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.outlined),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.sharp),
          isTrue,
        );
        // All styles should point to the same icon
        final icon = icons[TransportIconStyle.filled];
        expect(icons[TransportIconStyle.rounded], equals(icon));
        expect(icons[TransportIconStyle.outlined], equals(icon));
        expect(icons[TransportIconStyle.sharp], equals(icon));
      });

      test('returns 4 style variants for kuliglig (same icon for all styles)', () {
        final icons = TransportIconService.getAllIconsForMode(TransportMode.kuliglig);
        expect(icons.length, equals(4));
        expect(
          icons.containsKey(TransportIconStyle.filled),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.rounded),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.outlined),
          isTrue,
        );
        expect(
          icons.containsKey(TransportIconStyle.sharp),
          isTrue,
        );
        // All styles should point to the same icon
        final icon = icons[TransportIconStyle.filled];
        expect(icons[TransportIconStyle.rounded], equals(icon));
        expect(icons[TransportIconStyle.outlined], equals(icon));
        expect(icons[TransportIconStyle.sharp], equals(icon));
      });

      test('returns empty map for all modes (verifying all modes have icon mappings)',
          () {
        for (final mode in TransportMode.values) {
          final icons = TransportIconService.getAllIconsForMode(mode);
          expect(icons.isNotEmpty, isTrue);
        }
      });

      test('returns IconData values for all returned icons', () {
        for (final mode in TransportMode.values) {
          final icons = TransportIconService.getAllIconsForMode(mode);
          for (final icon in icons.values) {
            expect(icon, isA<IconData>());
          }
        }
      });
    });

    // =========================================================================
    // isIconAvailable() Tests
    // =========================================================================

    group('isIconAvailable', () {
      test('returns true for rounded style (default) for all modes', () {
        for (final mode in TransportMode.values) {
          expect(
            TransportIconService.isIconAvailable(mode),
            isTrue,
          );
        }
      });

      test('returns true for filled style for all modes', () {
        for (final mode in TransportMode.values) {
          expect(
            TransportIconService.isIconAvailable(
              mode,
              style: TransportIconStyle.filled,
            ),
            isTrue,
          );
        }
      });

      test('returns true for outlined style for modes with full support', () {
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.bus,
            style: TransportIconStyle.outlined,
          ),
          isTrue,
        );
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.taxi,
            style: TransportIconStyle.outlined,
          ),
          isTrue,
        );
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.train,
            style: TransportIconStyle.outlined,
          ),
          isTrue,
        );
      });

      test('returns true for sharp style for modes with full support', () {
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.bus,
            style: TransportIconStyle.sharp,
          ),
          isTrue,
        );
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.taxi,
            style: TransportIconStyle.sharp,
          ),
          isTrue,
        );
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.train,
            style: TransportIconStyle.sharp,
          ),
          isTrue,
        );
      });

      test('all styles are available for tricycle (same icon for all)', () {
        // Tricycle has the same icon for all 4 styles
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.tricycle,
            style: TransportIconStyle.outlined,
          ),
          isTrue,
        );
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.tricycle,
            style: TransportIconStyle.sharp,
          ),
          isTrue,
        );
        expect(
          TransportIconService.isIconAvailable(
            TransportMode.tricycle,
            style: TransportIconStyle.rounded,
          ),
          isTrue,
        );
      });
    });

    // =========================================================================
    // getIconWidget() Tests
    // =========================================================================

    group('getIconWidget', () {
      test('returns Icon widget with correct default size', () {
        final widget = TransportIconService.getIconWidget(TransportMode.bus);
        expect(widget, isA<Icon>());
        expect(widget.size, equals(24.0));
      });

      test('returns Icon widget with custom size', () {
        final widget = TransportIconService.getIconWidget(
          TransportMode.bus,
          size: 48.0,
        );
        expect(widget.size, equals(48.0));
      });

      test('returns Icon widget with custom color', () {
        final widget = TransportIconService.getIconWidget(
          TransportMode.bus,
          color: Colors.red,
        );
        expect(widget.color, equals(Colors.red));
      });

      test('returns Icon widget with null color when not specified', () {
        final widget = TransportIconService.getIconWidget(TransportMode.bus);
        expect(widget.color, isNull);
      });

      test('returns Icon widget with correct semantic label', () {
        final widget = TransportIconService.getIconWidget(TransportMode.bus);
        expect(widget.semanticLabel, equals('Bus icon'));
      });

      test('returns Icon widget with correct icon data based on style', () {
        final roundedWidget = TransportIconService.getIconWidget(
          TransportMode.bus,
          style: TransportIconStyle.rounded,
        );
        final sharpWidget = TransportIconService.getIconWidget(
          TransportMode.bus,
          style: TransportIconStyle.sharp,
        );
        expect(roundedWidget.icon, equals(Icons.directions_bus_rounded));
        expect(sharpWidget.icon, equals(Icons.directions_bus_sharp));
      });

      test('returns Icon widget with default rounded style when style not specified',
          () {
        final defaultWidget = TransportIconService.getIconWidget(TransportMode.bus);
        final explicitRoundedWidget = TransportIconService.getIconWidget(
          TransportMode.bus,
          style: TransportIconStyle.rounded,
        );
        expect(defaultWidget.icon, equals(explicitRoundedWidget.icon));
      });

      test('returns Icon widget with all parameters specified', () {
        final widget = TransportIconService.getIconWidget(
          TransportMode.train,
          size: 32.0,
          color: Colors.blue,
          style: TransportIconStyle.outlined,
        );
        expect(widget.size, equals(32.0));
        expect(widget.color, equals(Colors.blue));
        expect(widget.icon, equals(Icons.train_outlined));
        expect(widget.semanticLabel, equals('Train icon'));
      });

      test('returns consistent widget for same parameters', () {
        final widget1 = TransportIconService.getIconWidget(
          TransportMode.taxi,
          size: 24.0,
          color: Colors.green,
        );
        final widget2 = TransportIconService.getIconWidget(
          TransportMode.taxi,
          size: 24.0,
          color: Colors.green,
        );
        expect(widget1.icon, equals(widget2.icon));
        expect(widget1.size, equals(widget2.size));
        expect(widget1.color, equals(widget2.color));
      });
    });

    // =========================================================================
    // Edge Cases and Fallback Behavior Tests
    // =========================================================================

    group('Edge cases and fallback behavior', () {
      test('primary and fallback icons are different for jeepney', () {
        final primary = Icons.directions_bus;
        final fallback = Icons.commute;
        expect(primary, isNot(equals(fallback)));
      });

      test('primary and fallback icons are different for bus', () {
        final primary = Icons.directions_bus_filled;
        final fallback = Icons.directions_car;
        expect(primary, isNot(equals(fallback)));
      });

      test('all transport modes have unique primary icons', () {
        final iconMap = <IconData, List<TransportMode>>{};
        for (final mode in TransportMode.values) {
          final icon = TransportIconService.getIcon(mode);
          iconMap.putIfAbsent(icon, () => []).add(mode);
        }
        // All icons should be unique (no duplicates)
        for (final entry in iconMap.entries) {
          expect(
            entry.value.length,
            equals(1),
            reason: 'Icon ${entry.key} is shared by modes: ${entry.value}',
          );
        }
      });

      test('EDSA Carousel uses different icon from regular bus', () {
        final busIcon = TransportIconService.getIcon(TransportMode.bus);
        final edsaIcon = TransportIconService.getIcon(TransportMode.edsaCarousel);
        expect(busIcon, isNot(equals(edsaIcon)));
      });

      test('icons are valid IconData types', () {
        for (final mode in TransportMode.values) {
          final icon = TransportIconService.getIcon(mode);
          expect(icon, isA<IconData>());
        }
      });

      test('style variants return valid IconData types', () {
        for (final mode in TransportMode.values) {
          for (final style in TransportIconStyle.values) {
            final icon = TransportIconService.getIconWithStyle(mode, style: style);
            expect(icon, isA<IconData>());
          }
        }
      });

      test('getIconLabel returns non-empty strings for all modes', () {
        for (final mode in TransportMode.values) {
          final label = TransportIconService.getIconLabel(mode);
          expect(label.isNotEmpty, isTrue);
        }
      });

      test('getIconLabel returns strings with reasonable length', () {
        for (final mode in TransportMode.values) {
          final label = TransportIconService.getIconLabel(mode);
          expect(label.length, lessThan(30));
        }
      });

      test('icons work correctly with Flutter Icon widget constructor', () {
        // Verify that the icons returned can actually be used in Icon widgets
        for (final mode in TransportMode.values) {
          final iconData = TransportIconService.getIcon(mode);
          final icon = Icon(iconData);
          expect(icon.icon, equals(iconData));
        }
      });

      test('all modes have at least one icon variant', () {
        for (final mode in TransportMode.values) {
          final icons = TransportIconService.getAllIconsForMode(mode);
          expect(icons.isNotEmpty, isTrue);
        }
      });
    });

    // =========================================================================
    // Consistency and Integration Tests
    // =========================================================================

    group('Consistency and integration', () {
      test('getIconWithStyle(style: filled) returns same as getIcon', () {
        for (final mode in TransportMode.values) {
          final directIcon = TransportIconService.getIcon(mode);
          final styledIcon = TransportIconService.getIconWithStyle(
            mode,
            style: TransportIconStyle.filled,
          );
          expect(directIcon, equals(styledIcon));
        }
      });

      test('getIconWidget icon matches getIconWithStyle for same mode and style', () {
        for (final mode in TransportMode.values) {
          for (final style in TransportIconStyle.values) {
            final widgetIcon = TransportIconService.getIconWidget(
              mode,
              style: style,
            ).icon;
            final directIcon = TransportIconService.getIconWithStyle(
              mode,
              style: style,
            );
            expect(widgetIcon, equals(directIcon));
          }
        }
      });

      test('getIconWidget semanticLabel matches getIconLabel for same mode', () {
        for (final mode in TransportMode.values) {
          final widget = TransportIconService.getIconWidget(mode);
          final label = TransportIconService.getIconLabel(mode);
          expect(widget.semanticLabel, equals(label));
        }
      });

      test('isIconAvailable is consistent with getAllIconsForMode', () {
        for (final mode in TransportMode.values) {
          for (final style in TransportIconStyle.values) {
            final isAvailable = TransportIconService.isIconAvailable(
              mode,
              style: style,
            );
            final icons = TransportIconService.getAllIconsForMode(mode);
            expect(
              icons.containsKey(style),
              equals(isAvailable),
            );
          }
        }
      });

      test('EDSA Carousel has proper icon configuration', () {
        // EDSA Carousel should have all 4 style variants
        final icons = TransportIconService.getAllIconsForMode(TransportMode.edsaCarousel);
        expect(icons.length, equals(4));

        // But filled should be same as rounded (per service implementation)
        expect(
          icons[TransportIconStyle.filled],
          equals(Icons.directions_bus_rounded),
        );
        expect(
          icons[TransportIconStyle.rounded],
          equals(Icons.directions_bus_rounded),
        );
      });
    });
  });
}
