import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/presentation/widgets/app_logo_widget.dart';

void main() {
  // Helper function to wrap widget in MaterialApp for testing
  Widget createWidgetUnderTest({
    AppLogoSize size = AppLogoSize.large,
    bool showShadow = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppLogoWidget(size: size, showShadow: showShadow),
        ),
      ),
    );
  }

  group('AppLogoWidget', () {
    // ============================================================
    // Happy Path Tests
    // ============================================================
    group('Happy Path - Default rendering', () {
      testWidgets('renders without errors with default parameters', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(AppLogoWidget), findsOneWidget);
      });

      testWidgets('renders the bus icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      });

      testWidgets('default size is large', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: AppLogoWidget())),
          ),
        );

        // Find the outer container (first Container which is the AppLogoWidget's root)
        final appLogoWidget = tester.widget<AppLogoWidget>(
          find.byType(AppLogoWidget),
        );
        expect(appLogoWidget.size, equals(AppLogoSize.large));
      });

      testWidgets('default showShadow is true', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: AppLogoWidget())),
          ),
        );

        final appLogoWidget = tester.widget<AppLogoWidget>(
          find.byType(AppLogoWidget),
        );
        expect(appLogoWidget.showShadow, isTrue);
      });
    });

    // ============================================================
    // Size Variant Tests
    // ============================================================
    group('Size Variants - Small', () {
      testWidgets('small size renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.small));

        expect(find.byType(AppLogoWidget), findsOneWidget);
        expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      });

      testWidgets('small size has correct outer dimensions (40x40)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.small));

        // Find the Semantics widget which wraps the outer Container
        final semanticsFinder = find.bySemanticsLabel(
          'PH Fare Calculator logo',
        );
        expect(semanticsFinder, findsOneWidget);

        // Get the Container inside Semantics (the outer container)
        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        // The first Container is the outer one
        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;

        expect(outerContainer.constraints?.maxWidth, equals(40.0));
        expect(outerContainer.constraints?.maxHeight, equals(40.0));
      });

      testWidgets('small size has correct icon size (16px)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.small));

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.directions_bus_rounded),
        );
        expect(icon.size, equals(16.0));
      });
    });

    group('Size Variants - Medium', () {
      testWidgets('medium size renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.medium),
        );

        expect(find.byType(AppLogoWidget), findsOneWidget);
        expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      });

      testWidgets('medium size has correct outer dimensions (80x80)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.medium),
        );

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;

        expect(outerContainer.constraints?.maxWidth, equals(80.0));
        expect(outerContainer.constraints?.maxHeight, equals(80.0));
      });

      testWidgets('medium size has correct icon size (32px)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.medium),
        );

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.directions_bus_rounded),
        );
        expect(icon.size, equals(32.0));
      });
    });

    group('Size Variants - Large', () {
      testWidgets('large size renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.large));

        expect(find.byType(AppLogoWidget), findsOneWidget);
        expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      });

      testWidgets('large size has correct outer dimensions (140x140)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.large));

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;

        expect(outerContainer.constraints?.maxWidth, equals(140.0));
        expect(outerContainer.constraints?.maxHeight, equals(140.0));
      });

      testWidgets('large size has correct icon size (56px)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.large));

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.directions_bus_rounded),
        );
        expect(icon.size, equals(56.0));
      });
    });

    // ============================================================
    // Shadow Tests
    // ============================================================
    group('Shadow Variations', () {
      testWidgets('renders with shadow when showShadow is true', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(showShadow: true));

        // Find the outer container
        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration;

        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, isNotEmpty);
      });

      testWidgets('renders without shadow when showShadow is false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(showShadow: false));

        // Find the outer container
        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration;

        expect(decoration.boxShadow, isNull);
      });

      testWidgets('shadow has correct properties for large size', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.large, showShadow: true),
        );

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration;

        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));

        final shadow = decoration.boxShadow!.first;
        expect(shadow.blurRadius, equals(24.0)); // Large size shadowBlur
        expect(shadow.offset, equals(const Offset(0, 8))); // Large shadowOffset
      });

      testWidgets('shadow has correct properties for small size', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.small, showShadow: true),
        );

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration;

        expect(decoration.boxShadow, isNotNull);
        final shadow = decoration.boxShadow!.first;
        expect(shadow.blurRadius, equals(8.0)); // Small size shadowBlur
        expect(shadow.offset, equals(const Offset(0, 2))); // Small shadowOffset
      });
    });

    // ============================================================
    // Accessibility Tests
    // ============================================================
    group('Accessibility', () {
      testWidgets('has correct semantics label', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(
          find.bySemanticsLabel('PH Fare Calculator logo'),
          findsOneWidget,
        );
      });

      testWidgets('semantics label is present for all sizes', (
        WidgetTester tester,
      ) async {
        // Test small
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.small));
        expect(
          find.bySemanticsLabel('PH Fare Calculator logo'),
          findsOneWidget,
        );

        // Test medium
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.medium),
        );
        expect(
          find.bySemanticsLabel('PH Fare Calculator logo'),
          findsOneWidget,
        );

        // Test large
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.large));
        expect(
          find.bySemanticsLabel('PH Fare Calculator logo'),
          findsOneWidget,
        );
      });
    });

    // ============================================================
    // Visual Styling Tests
    // ============================================================
    group('Visual Styling', () {
      testWidgets('outer container has theme-aware surface background', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration;

        // Background uses theme's colorScheme.surface which adapts to light/dark mode
        expect(decoration.color, isNotNull);
      });

      testWidgets('outer container has circular shape', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester.widgetList<Container>(containerFinder);
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration;

        expect(decoration.shape, equals(BoxShape.circle));
      });

      testWidgets('inner container has gradient', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester
            .widgetList<Container>(containerFinder)
            .toList();
        // The second Container is the inner one with gradient
        final innerContainer = containers[1];
        final decoration = innerContainer.decoration as BoxDecoration;

        expect(decoration.gradient, isNotNull);
        expect(decoration.gradient, isA<LinearGradient>());
      });

      testWidgets('icon color is white', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.directions_bus_rounded),
        );
        expect(icon.color, equals(Colors.white));
      });
    });

    // ============================================================
    // Inner Container Dimension Tests
    // ============================================================
    group('Inner Container Dimensions', () {
      testWidgets('small size has correct inner dimensions (28x28)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.small));

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester
            .widgetList<Container>(containerFinder)
            .toList();
        // Second container is the inner one
        final innerContainer = containers[1];

        expect(innerContainer.constraints?.maxWidth, equals(28.0));
        expect(innerContainer.constraints?.maxHeight, equals(28.0));
      });

      testWidgets('medium size has correct inner dimensions (56x56)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidgetUnderTest(size: AppLogoSize.medium),
        );

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester
            .widgetList<Container>(containerFinder)
            .toList();
        final innerContainer = containers[1];

        expect(innerContainer.constraints?.maxWidth, equals(56.0));
        expect(innerContainer.constraints?.maxHeight, equals(56.0));
      });

      testWidgets('large size has correct inner dimensions (100x100)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(size: AppLogoSize.large));

        final containerFinder = find.descendant(
          of: find.byType(AppLogoWidget),
          matching: find.byType(Container),
        );

        final containers = tester
            .widgetList<Container>(containerFinder)
            .toList();
        final innerContainer = containers[1];

        expect(innerContainer.constraints?.maxWidth, equals(100.0));
        expect(innerContainer.constraints?.maxHeight, equals(100.0));
      });
    });

    // ============================================================
    // Edge Cases
    // Note: This widget has no null/undefined inputs, boundary values,
    // invalid data, or error states because:
    // - size is a fixed enum with 3 values (no invalid inputs possible)
    // - showShadow is a boolean with a default value
    // - No async operations or network calls
    // - No error states to handle
    // Performance and concurrency tests are not applicable for this
    // simple presentational widget.
    // ============================================================
  });

  // ============================================================
  // AppLogoSize Enum Tests
  // ============================================================
  group('AppLogoSize Enum', () {
    test('enum has exactly 3 values', () {
      expect(AppLogoSize.values.length, equals(3));
    });

    test('enum contains small, medium, and large', () {
      expect(AppLogoSize.values, contains(AppLogoSize.small));
      expect(AppLogoSize.values, contains(AppLogoSize.medium));
      expect(AppLogoSize.values, contains(AppLogoSize.large));
    });
  });
}
