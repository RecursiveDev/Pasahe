import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_estimator/src/models/fare_formula.dart';
import 'package:ph_fare_estimator/src/models/location.dart';
import 'package:ph_fare_estimator/src/presentation/screens/main_screen.dart';
import 'package:ph_fare_estimator/src/presentation/widgets/fare_result_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mocks.dart';

void main() {
  late MockGeocodingService mockGeocodingService;
  late MockHybridEngine mockHybridEngine;
  late MockFareCacheService mockFareCacheService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockGeocodingService = MockGeocodingService();
    mockHybridEngine = MockHybridEngine();
    mockFareCacheService = MockFareCacheService();

    // Setup default mock behaviors
    mockFareCacheService.formulasToReturn = [
      FareFormula(
        mode: 'Jeepney',
        subType: 'Traditional',
        baseFare: 12.0,
        perKmRate: 1.8,
      ),
      FareFormula(
        mode: 'Taxi',
        subType: 'White (Regular)',
        baseFare: 45.0,
        perKmRate: 13.5,
      ),
    ];
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MainScreen(
        geocodingService: mockGeocodingService,
        hybridEngine: mockHybridEngine,
        fareCacheService: mockFareCacheService,
      ),
    );
  }

  testWidgets('MainScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Wait for init

    expect(find.text('Fare Estimator'), findsOneWidget);
    expect(find.text('Origin'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('Calculate Fare'), findsOneWidget);
  });

  testWidgets('Populates results when Calculate Fare is pressed', (
    WidgetTester tester,
  ) async {
    // Setup data
    final origin = Location(name: 'Luneta', latitude: 14.58, longitude: 120.97);
    final destination = Location(
      name: 'MOA',
      latitude: 14.53,
      longitude: 120.98,
    );

    mockGeocodingService.locationsToReturn = [origin];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Search and select Origin
    await tester.enterText(find.widgetWithText(TextField, 'Origin'), 'Luneta');
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // wait for autocomplete debounce/async
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luneta').last); // Select from options
    await tester.pumpAndSettle(); // Close options

    // 2. Search and select Destination
    mockGeocodingService.locationsToReturn = [destination];
    await tester.enterText(
      find.widgetWithText(TextField, 'Destination'),
      'MOA',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MOA').last);
    await tester.pumpAndSettle();

    // 3. Tap Calculate
    await tester.tap(find.text('Calculate Fare'));
    await tester.pumpAndSettle();

    // 4. Verify Results
    // Check if error message is showing instead
    expect(find.textContaining('Could not calculate fare'), findsNothing);

    expect(find.byType(FareResultCard), findsWidgets);
  });
}
