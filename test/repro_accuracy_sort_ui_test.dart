import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/core/constants/region_constants.dart';
import 'package:ph_fare_calculator/src/models/accuracy_level.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/route_result.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/presentation/widgets/main_screen/fare_results_list.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/services/transport_mode_filter_service.dart';

/// Regression test for BUG-001: Accuracy inconsistency in sort options
///
/// Root cause: `_buildGroupedList()` in `fare_results_list.dart` was not
/// passing `accuracy` and `routeSource` parameters to `FareResultCard`,
/// causing them to use default values instead of actual values from FareResult.
///
/// This caused "Lowest Price" and "Highest Price" to always show
/// "Precise (Online)" even in offline mode.
void main() {
  late FareComparisonService fareComparisonService;

  setUp(() {
    fareComparisonService = FareComparisonService(
      _MockTransportModeFilterService(),
    );
  });

  group('REGRESSION: Accuracy display in FareResultsList', () {
    testWidgets('Lowest Overall (flat list) shows correct accuracy', (tester) async {
      // Create results with offline accuracy
      final results = [
        _createFareResult('Jeepney', 20.0, AccuracyLevel.approximate),
        _createFareResult('Taxi', 150.0, AccuracyLevel.approximate),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FareResultsList(
              fareResults: results,
              sortCriteria: SortCriteria.lowestOverall,
              fareComparisonService: fareComparisonService,
            ),
          ),
        ),
      );

      // Verify accuracy badge is visible with offline icon
      expect(find.byIcon(Icons.offline_bolt_rounded), findsWidgets);

      // Verify accuracy label shows offline text
      expect(find.text('Approximate (Offline)'), findsWidgets);
    });

    testWidgets('Lowest Price (grouped list) shows correct accuracy',
        (tester) async {
      // Create results with offline accuracy
      final results = [
        _createFareResult('Jeepney (Traditional)', 20.0, AccuracyLevel.approximate),
        _createFareResult('Jeepney (Modern)', 25.0, AccuracyLevel.approximate),
        _createFareResult('Taxi (Standard)', 150.0, AccuracyLevel.approximate),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FareResultsList(
              fareResults: results,
              sortCriteria: SortCriteria.priceAsc,
              fareComparisonService: fareComparisonService,
            ),
          ),
        ),
      );

      // Verify accuracy badge is visible with offline icon
      expect(find.byIcon(Icons.offline_bolt_rounded), findsWidgets);

      // Verify accuracy label shows offline text
      expect(find.text('Approximate (Offline)'), findsWidgets);
    });

    testWidgets('Highest Price (grouped list) shows correct accuracy',
        (tester) async {
      // Create results with offline accuracy
      final results = [
        _createFareResult('Jeepney (Traditional)', 20.0, AccuracyLevel.approximate),
        _createFareResult('Taxi (Standard)', 150.0, AccuracyLevel.approximate),
        _createFareResult('Taxi (Premium)', 200.0, AccuracyLevel.approximate),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FareResultsList(
              fareResults: results,
              sortCriteria: SortCriteria.priceDesc,
              fareComparisonService: fareComparisonService,
            ),
          ),
        ),
      );

      // Verify accuracy badge is visible with offline icon
      expect(find.byIcon(Icons.offline_bolt_rounded), findsWidgets);

      // Verify accuracy label shows offline text
      expect(find.text('Approximate (Offline)'), findsWidgets);
    });

    testWidgets('Estimated (Cached) accuracy is displayed correctly',
        (tester) async {
      // Create results with estimated accuracy
      final results = [
        _createFareResult('Jeepney', 20.0, AccuracyLevel.estimated),
        _createFareResult('Taxi', 150.0, AccuracyLevel.estimated),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FareResultsList(
              fareResults: results,
              sortCriteria: SortCriteria.lowestOverall,
              fareComparisonService: fareComparisonService,
            ),
          ),
        ),
      );

      // Verify accuracy badge shows cached icon
      expect(find.byIcon(Icons.cached_rounded), findsWidgets);

      // Verify accuracy label shows cached text
      expect(find.text('Estimated (Cached)'), findsWidgets);
    });

    testWidgets('Precise (Online) accuracy is displayed correctly',
        (tester) async {
      // Create results with precise accuracy
      final results = [
        _createFareResult('Jeepney', 20.0, AccuracyLevel.precise),
        _createFareResult('Taxi', 150.0, AccuracyLevel.precise),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FareResultsList(
              fareResults: results,
              sortCriteria: SortCriteria.lowestOverall,
              fareComparisonService: fareComparisonService,
            ),
          ),
        ),
      );

      // Verify accuracy badge shows wifi icon
      expect(find.byIcon(Icons.wifi_rounded), findsWidgets);

      // Verify accuracy label shows precise text
      expect(find.text('Precise (Online)'), findsWidgets);
    });

    testWidgets('Route source is displayed correctly in all sort options',
        (tester) async {
      // Create results with different route sources
      final results = [
        FareResult(
          transportMode: 'Jeepney',
          fare: 20.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 20.0,
          accuracy: AccuracyLevel.approximate,
          routeSource: RouteSource.haversine,
        ),
        FareResult(
          transportMode: 'Taxi',
          fare: 150.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 150.0,
          accuracy: AccuracyLevel.precise,
          routeSource: RouteSource.osrm,
        ),
      ];

      // Test with grouped list (priceAsc)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FareResultsList(
              fareResults: results,
              sortCriteria: SortCriteria.priceAsc,
              fareComparisonService: fareComparisonService,
            ),
          ),
        ),
      );

      // Verify both route sources are displayed
      expect(find.text('Estimated (straight-line)'), findsOneWidget);
      expect(find.text('Road route'), findsOneWidget);
    });

    testWidgets(
        'REGRESSION BUG-001: All sort options must preserve accuracy level',
        (tester) async {
      // Create results with approximate (offline) accuracy
      final results = [
        _createFareResult('Jeepney (Traditional)', 20.0, AccuracyLevel.approximate),
        _createFareResult('Taxi (Standard)', 150.0, AccuracyLevel.approximate),
      ];

      for (final criteria in [
        SortCriteria.lowestOverall,
        SortCriteria.priceAsc,
        SortCriteria.priceDesc,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FareResultsList(
                fareResults: results,
                sortCriteria: criteria,
                fareComparisonService: fareComparisonService,
              ),
            ),
          ),
        );

        // Verify offline accuracy is displayed (not default precise)
        expect(find.text('Approximate (Offline)'), findsWidgets,
            reason:
                'Accuracy should be displayed for sort criteria: $criteria');

        // Verify online accuracy is NOT displayed (regression check)
        expect(find.text('Precise (Online)'), findsNothing,
            reason:
                'Should not show default precision for offline results when using: $criteria');
      }
    });
  });
}

FareResult _createFareResult(
  String transportMode,
  double fare,
  AccuracyLevel accuracy,
) {
  return FareResult(
    transportMode: transportMode,
    fare: fare,
    indicatorLevel: IndicatorLevel.standard,
    isRecommended: false,
    passengerCount: 1,
    totalFare: fare,
    accuracy: accuracy,
    routeSource: accuracy == AccuracyLevel.approximate
        ? RouteSource.haversine
        : RouteSource.osrm,
  );
}

class _MockTransportModeFilterService
    implements TransportModeFilterService {
  @override
  bool isModeValid(TransportMode mode, double lat, double lng) => true;

  @override
  List<TransportMode> getAvailableModes(double lat, double lng) =>
      TransportMode.values;

  @override
  Region getRegionForLocation(double lat, double lng) => Region.nationwide;
}
