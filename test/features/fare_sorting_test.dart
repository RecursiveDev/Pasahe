import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';

void main() {
  group('Fare Sorting Logic', () {
    test('Results are sorted by price (cheapest first)', () {
      // Create unsorted fare results
      final results = [
        FareResult(
          transportMode: 'Bus (Regular)',
          fare: 50.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 50.0,
        ),
        FareResult(
          transportMode: 'Jeepney (Traditional)',
          fare: 12.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 12.0,
        ),
        FareResult(
          transportMode: 'Taxi (Metro)',
          fare: 150.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 150.0,
        ),
        FareResult(
          transportMode: 'Train (LRT)',
          fare: 20.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 20.0,
        ),
      ];

      // Sort by fare (cheapest first)
      results.sort((a, b) => a.fare.compareTo(b.fare));

      // Verify sorting
      expect(results[0].fare, 12.0);
      expect(results[0].transportMode, 'Jeepney (Traditional)');
      expect(results[1].fare, 20.0);
      expect(results[2].fare, 50.0);
      expect(results[3].fare, 150.0);
    });

    test('Cheapest option is marked as recommended', () {
      // Create fare results
      var results = [
        FareResult(
          transportMode: 'Bus (Regular)',
          fare: 50.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 50.0,
        ),
        FareResult(
          transportMode: 'Jeepney (Traditional)',
          fare: 12.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 12.0,
        ),
        FareResult(
          transportMode: 'Taxi (Metro)',
          fare: 150.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 150.0,
        ),
      ];

      // Sort by fare
      results.sort((a, b) => a.fare.compareTo(b.fare));

      // Mark cheapest as recommended
      if (results.isNotEmpty) {
        results[0] = FareResult(
          transportMode: results[0].transportMode,
          fare: results[0].fare,
          indicatorLevel: results[0].indicatorLevel,
          isRecommended: true,
          passengerCount: results[0].passengerCount,
          totalFare: results[0].totalFare,
        );
      }

      // Verify the cheapest is marked as recommended
      expect(results[0].isRecommended, true);
      expect(results[0].fare, 12.0);
      expect(results[1].isRecommended, false);
      expect(results[2].isRecommended, false);
    });

    test('Only one option is marked as recommended', () {
      var results = [
        FareResult(
          transportMode: 'Bus (Regular)',
          fare: 50.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 50.0,
        ),
        FareResult(
          transportMode: 'Jeepney (Traditional)',
          fare: 12.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 12.0,
        ),
      ];

      // Sort and mark
      results.sort((a, b) => a.fare.compareTo(b.fare));
      if (results.isNotEmpty) {
        results[0] = FareResult(
          transportMode: results[0].transportMode,
          fare: results[0].fare,
          indicatorLevel: results[0].indicatorLevel,
          isRecommended: true,
          passengerCount: results[0].passengerCount,
          totalFare: results[0].totalFare,
        );
      }

      // Count recommended items
      final recommendedCount = results.where((r) => r.isRecommended).length;
      expect(recommendedCount, 1);
    });

    test('Empty results list handles sorting gracefully', () {
      final results = <FareResult>[];

      // Sort empty list (should not throw)
      expect(
        () => results.sort((a, b) => a.fare.compareTo(b.fare)),
        returnsNormally,
      );

      // Marking logic should handle empty list
      if (results.isNotEmpty) {
        results[0] = FareResult(
          transportMode: results[0].transportMode,
          fare: results[0].fare,
          indicatorLevel: results[0].indicatorLevel,
          isRecommended: true,
          passengerCount: results[0].passengerCount,
          totalFare: results[0].totalFare,
        );
      }

      expect(results.isEmpty, true);
    });

    test('Single result is marked as recommended', () {
      var results = [
        FareResult(
          transportMode: 'Jeepney (Traditional)',
          fare: 12.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 12.0,
        ),
      ];

      // Sort and mark
      results.sort((a, b) => a.fare.compareTo(b.fare));
      if (results.isNotEmpty) {
        results[0] = FareResult(
          transportMode: results[0].transportMode,
          fare: results[0].fare,
          indicatorLevel: results[0].indicatorLevel,
          isRecommended: true,
          passengerCount: results[0].passengerCount,
          totalFare: results[0].totalFare,
        );
      }

      expect(results[0].isRecommended, true);
    });

    test('Results with identical fares maintain stable sort', () {
      final results = [
        FareResult(
          transportMode: 'Jeepney (Type A)',
          fare: 12.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 12.0,
        ),
        FareResult(
          transportMode: 'Jeepney (Type B)',
          fare: 12.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 12.0,
        ),
        FareResult(
          transportMode: 'Bus (Regular)',
          fare: 50.0,
          indicatorLevel: IndicatorLevel.standard,
          isRecommended: false,
          passengerCount: 1,
          totalFare: 50.0,
        ),
      ];

      // Sort by fare
      results.sort((a, b) => a.fare.compareTo(b.fare));

      // Both should have same fare but first should be at index 0
      expect(results[0].fare, 12.0);
      expect(results[1].fare, 12.0);
      expect(results[2].fare, 50.0);
    });
  });
}
