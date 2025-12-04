import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/services/transport_mode_filter_service.dart';
import 'package:ph_fare_calculator/src/core/constants/region_constants.dart';
import 'package:ph_fare_calculator/src/models/transport_mode.dart';
import 'package:ph_fare_calculator/src/models/region_config.dart';

void main() {
  late TransportModeFilterService service;

  setUp(() {
    service = TransportModeFilterService();
  });

  group('TransportModeFilterService', () {
    group('getRegionForLocation', () {
      test('returns NCR for coordinates within Metro Manila (Luneta Park)', () {
        // Luneta Park, Manila: 14.5831, 120.9794
        final region = service.getRegionForLocation(14.5831, 120.9794);
        expect(region, equals(Region.ncr));
      });

      test('returns NCR for coordinates within Metro Manila (Quezon City)', () {
        // Quezon City: 14.6760, 121.0437
        final region = service.getRegionForLocation(14.6760, 121.0437);
        expect(region, equals(Region.ncr));
      });

      test(
        'returns Cebu for coordinates within Metro Cebu (Magellan Cross)',
        () {
          // Magellan's Cross, Cebu: 10.2934, 123.9021
          final region = service.getRegionForLocation(10.2934, 123.9021);
          expect(region, equals(Region.cebu));
        },
      );

      test('returns Davao for coordinates within Davao City', () {
        // Davao City: 7.0731, 125.6128
        final region = service.getRegionForLocation(7.0731, 125.6128);
        expect(region, equals(Region.davao));
      });

      test('returns CDO for coordinates within Cagayan de Oro', () {
        // CDO: 8.4542, 124.6319
        final region = service.getRegionForLocation(8.4542, 124.6319);
        expect(region, equals(Region.cdo));
      });

      test('returns Luzon for coordinates in Luzon but outside NCR', () {
        // Baguio City: 16.4023, 120.5960
        final region = service.getRegionForLocation(16.4023, 120.5960);
        expect(region, equals(Region.luzon));
      });

      test('returns Visayas for coordinates in Visayas but outside Cebu', () {
        // Iloilo City: 10.7202, 122.5621
        final region = service.getRegionForLocation(10.7202, 122.5621);
        expect(region, equals(Region.visayas));
      });

      test(
        'returns Mindanao for coordinates in Mindanao but outside specific cities',
        () {
          // General Santos City: 6.1164, 125.1716
          final region = service.getRegionForLocation(6.1164, 125.1716);
          expect(region, equals(Region.mindanao));
        },
      );
    });

    group('getAvailableModes', () {
      test('returns EDSA Carousel only for NCR locations', () {
        // Luneta Park (NCR)
        final modesNCR = service.getAvailableModes(14.5831, 120.9794);
        expect(modesNCR, contains(TransportMode.edsaCarousel));

        // Cebu City (Visayas)
        final modesCebu = service.getAvailableModes(10.2934, 123.9021);
        expect(modesCebu, isNot(contains(TransportMode.edsaCarousel)));

        // Davao City (Mindanao)
        final modesDavao = service.getAvailableModes(7.0731, 125.6128);
        expect(modesDavao, isNot(contains(TransportMode.edsaCarousel)));
      });

      test('returns Train for NCR and Luzon locations only', () {
        // Luneta Park (NCR)
        final modesNCR = service.getAvailableModes(14.5831, 120.9794);
        expect(modesNCR, contains(TransportMode.train));

        // Baguio (Luzon outside NCR)
        final modesLuzon = service.getAvailableModes(16.4023, 120.5960);
        expect(modesLuzon, contains(TransportMode.train));

        // Cebu City (Visayas) - No trains
        final modesCebu = service.getAvailableModes(10.2934, 123.9021);
        expect(modesCebu, isNot(contains(TransportMode.train)));

        // Davao City (Mindanao) - No trains
        final modesDavao = service.getAvailableModes(7.0731, 125.6128);
        expect(modesDavao, isNot(contains(TransportMode.train)));
      });

      test('returns Jeepney nationwide', () {
        // NCR
        final modesNCR = service.getAvailableModes(14.5831, 120.9794);
        expect(modesNCR, contains(TransportMode.jeepney));

        // Cebu
        final modesCebu = service.getAvailableModes(10.2934, 123.9021);
        expect(modesCebu, contains(TransportMode.jeepney));

        // Davao
        final modesDavao = service.getAvailableModes(7.0731, 125.6128);
        expect(modesDavao, contains(TransportMode.jeepney));
      });

      test('returns Tricycle nationwide', () {
        // NCR
        final modesNCR = service.getAvailableModes(14.5831, 120.9794);
        expect(modesNCR, contains(TransportMode.tricycle));

        // Cebu
        final modesCebu = service.getAvailableModes(10.2934, 123.9021);
        expect(modesCebu, contains(TransportMode.tricycle));

        // Mindanao
        final modesMindanao = service.getAvailableModes(6.1164, 125.1716);
        expect(modesMindanao, contains(TransportMode.tricycle));
      });

      test('returns Taxi for major cities', () {
        // NCR
        final modesNCR = service.getAvailableModes(14.5831, 120.9794);
        expect(modesNCR, contains(TransportMode.taxi));

        // Cebu
        final modesCebu = service.getAvailableModes(10.2934, 123.9021);
        expect(modesCebu, contains(TransportMode.taxi));

        // Davao
        final modesDavao = service.getAvailableModes(7.0731, 125.6128);
        expect(modesDavao, contains(TransportMode.taxi));
      });
    });

    group('isModeValid', () {
      test('validates EDSA Carousel only in NCR', () {
        // Luneta Park (NCR) - valid
        expect(
          service.isModeValid(TransportMode.edsaCarousel, 14.5831, 120.9794),
          isTrue,
        );

        // Cebu City - invalid
        expect(
          service.isModeValid(TransportMode.edsaCarousel, 10.2934, 123.9021),
          isFalse,
        );
      });

      test('validates Train only in NCR and Luzon', () {
        // NCR - valid
        expect(
          service.isModeValid(TransportMode.train, 14.5831, 120.9794),
          isTrue,
        );

        // Cebu - invalid
        expect(
          service.isModeValid(TransportMode.train, 10.2934, 123.9021),
          isFalse,
        );
      });

      test('validates nationwide modes everywhere', () {
        // Jeepney in NCR
        expect(
          service.isModeValid(TransportMode.jeepney, 14.5831, 120.9794),
          isTrue,
        );

        // Jeepney in Mindanao
        expect(
          service.isModeValid(TransportMode.jeepney, 6.1164, 125.1716),
          isTrue,
        );

        // Tricycle in Cebu
        expect(
          service.isModeValid(TransportMode.tricycle, 10.2934, 123.9021),
          isTrue,
        );
      });
    });
  });

  group('RegionConfig', () {
    test('isModeAvailable returns true for nationwide modes in any region', () {
      expect(
        RegionConfig.isModeAvailable(TransportMode.jeepney, Region.ncr),
        isTrue,
      );
      expect(
        RegionConfig.isModeAvailable(TransportMode.jeepney, Region.cebu),
        isTrue,
      );
      expect(
        RegionConfig.isModeAvailable(TransportMode.jeepney, Region.mindanao),
        isTrue,
      );
    });

    test('isModeAvailable returns true for EDSA Carousel only in NCR', () {
      expect(
        RegionConfig.isModeAvailable(TransportMode.edsaCarousel, Region.ncr),
        isTrue,
      );
      expect(
        RegionConfig.isModeAvailable(TransportMode.edsaCarousel, Region.cebu),
        isFalse,
      );
      expect(
        RegionConfig.isModeAvailable(TransportMode.edsaCarousel, Region.davao),
        isFalse,
      );
    });

    test('isModeAvailable returns true for Train in NCR and Luzon', () {
      expect(
        RegionConfig.isModeAvailable(TransportMode.train, Region.ncr),
        isTrue,
      );
      expect(
        RegionConfig.isModeAvailable(TransportMode.train, Region.luzon),
        isTrue,
      );
      expect(
        RegionConfig.isModeAvailable(TransportMode.train, Region.visayas),
        isFalse,
      );
    });

    test('getModesForRegion returns correct modes for NCR', () {
      final modes = RegionConfig.getModesForRegion(Region.ncr);

      expect(modes, contains(TransportMode.jeepney));
      expect(modes, contains(TransportMode.tricycle));
      expect(modes, contains(TransportMode.bus));
      expect(modes, contains(TransportMode.taxi));
      expect(modes, contains(TransportMode.train));
      expect(modes, contains(TransportMode.edsaCarousel));
      expect(modes, contains(TransportMode.ferry));
    });

    test('getModesForRegion does not include Train for Visayas', () {
      final modes = RegionConfig.getModesForRegion(Region.visayas);

      expect(modes, contains(TransportMode.jeepney));
      expect(modes, contains(TransportMode.tricycle));
      expect(modes, isNot(contains(TransportMode.train)));
      expect(modes, isNot(contains(TransportMode.edsaCarousel)));
    });

    test('getRegionsForMode returns correct regions for EDSA Carousel', () {
      final regions = RegionConfig.getRegionsForMode(
        TransportMode.edsaCarousel,
      );

      expect(regions, contains(Region.ncr));
      expect(regions.length, equals(1));
    });

    test('getRegionsForMode returns nationwide for Jeepney', () {
      final regions = RegionConfig.getRegionsForMode(TransportMode.jeepney);

      expect(regions, contains(Region.nationwide));
    });
  });
}
