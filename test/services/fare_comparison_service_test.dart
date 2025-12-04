import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/services/fare_comparison_service.dart';
import 'package:ph_fare_calculator/src/services/transport_mode_filter_service.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';

void main() {
  late FareComparisonService service;
  late TransportModeFilterService filterService;

  setUp(() {
    filterService = TransportModeFilterService();
    service = FareComparisonService(filterService);
  });

  group('FareComparisonService', () {
    test('recommendModes returns correct modes for short distance (< 5km)', () {
      final modes = service.recommendModes(distanceInMeters: 4000);

      expect(modes, contains(TransportMode.jeepney));
      expect(modes, contains(TransportMode.tricycle));
      expect(modes, contains(TransportMode.taxi));
      expect(modes, contains(TransportMode.train)); // Metro Manila default
    });

    test(
      'recommendModes returns correct modes for medium distance (5km - 20km)',
      () {
        // 15km: Should contain Bus, UV, Taxi, but NOT Jeepney (since Jeepney is < 10km)
        final modes = service.recommendModes(distanceInMeters: 15000);

        expect(modes, contains(TransportMode.bus));
        expect(modes, contains(TransportMode.uvExpress));
        expect(modes, contains(TransportMode.taxi));
        expect(modes, isNot(contains(TransportMode.jeepney)));
      },
    );

    test('recommendModes includes Jeepney for medium distance < 10km', () {
      final modes = service.recommendModes(distanceInMeters: 8000);
      expect(modes, contains(TransportMode.jeepney));
    });

    test(
      'recommendModes returns correct modes for long distance (>= 20km)',
      () {
        final modes = service.recommendModes(distanceInMeters: 25000);

        expect(modes, contains(TransportMode.bus));
        expect(modes, contains(TransportMode.uvExpress));
        expect(modes, contains(TransportMode.taxi));
        expect(modes, isNot(contains(TransportMode.tricycle)));
      },
    );

    test('recommendModes adds Train and Ferry for Metro Manila', () {
      final modes = service.recommendModes(
        distanceInMeters: 5000,
        isMetroManila: true,
      );

      expect(modes, contains(TransportMode.train));
      expect(modes, contains(TransportMode.ferry));
    });

    test(
      'recommendModes does not add Train/Ferry for non-Metro Manila (default assumption)',
      () {
        // Current implementation might default isMetroManila=true in the parameter definition?
        // Checking source: recommendModes({required double distanceInMeters, bool isMetroManila = true})

        final modes = service.recommendModes(
          distanceInMeters: 5000,
          isMetroManila: false,
        );

        // Based on provided logic in previous turn:
        // if (isMetroManila) { add train, add ferry }

        expect(modes, isNot(contains(TransportMode.train)));
        expect(modes, isNot(contains(TransportMode.ferry)));
      },
    );
  });
}
