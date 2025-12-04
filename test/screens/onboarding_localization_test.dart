import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_calculator/src/presentation/screens/onboarding_screen.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/models/discount_type.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a real SettingsService to test the locale change logic
class FakeSettingsService implements SettingsService {
  Locale _locale = const Locale('en');

  @override
  Future<Locale> getLocale() async => _locale;

  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    // Important: Update the notifier used by the UI
    SettingsService.localeNotifier.value = locale;
  }

  // Stubs for other methods not relevant to this specific test
  bool provincialMode = false;
  @override
  Future<bool> getProvincialMode() async => provincialMode;
  @override
  Future<void> setProvincialMode(bool value) async {
    provincialMode = value;
  }

  TrafficFactor trafficFactor = TrafficFactor.medium;
  @override
  Future<TrafficFactor> getTrafficFactor() async => trafficFactor;
  @override
  Future<void> setTrafficFactor(TrafficFactor factor) async {
    trafficFactor = factor;
  }

  bool highContrast = false;
  @override
  Future<bool> getHighContrastEnabled() async => highContrast;
  @override
  Future<void> setHighContrastEnabled(bool value) async {
    highContrast = value;
  }

  DiscountType discountType = DiscountType.standard;
  @override
  Future<DiscountType> getUserDiscountType() async => discountType;
  @override
  Future<void> setUserDiscountType(DiscountType type) async {
    discountType = type;
  }

  Set<String> hiddenTransportModes = {};
  @override
  Future<Set<String>> getHiddenTransportModes() async => hiddenTransportModes;
  @override
  Future<void> toggleTransportMode(String modeSubType, bool isHidden) async {
    if (isHidden) {
      hiddenTransportModes.add(modeSubType);
    } else {
      hiddenTransportModes.remove(modeSubType);
    }
  }

  @override
  Future<bool> isTransportModeHidden(String mode, String subType) async {
    return hiddenTransportModes.contains('$mode::$subType');
  }

  Location? lastLocation;
  @override
  Future<void> saveLastLocation(Location location) async {
    lastLocation = location;
  }

  @override
  Future<Location?> getLastLocation() async {
    return lastLocation;
  }

  bool hasSetDiscount = false;
  @override
  Future<bool> hasSetDiscountType() async {
    return hasSetDiscount;
  }

  @override
  Future<Set<String>> getEnabledModes() async {
    return hiddenTransportModes;
  }

  @override
  Future<void> toggleMode(String modeId) async {
    final isCurrentlyHidden = hiddenTransportModes.contains(modeId);
    await toggleTransportMode(modeId, !isCurrentlyHidden);
  }
}

void main() {
  late FakeSettingsService fakeSettingsService;

  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues({});

    fakeSettingsService = FakeSettingsService();
    // Reset the static notifier
    SettingsService.localeNotifier.value = const Locale('en');

    final getIt = GetIt.instance;
    getIt.registerSingleton<SettingsService>(fakeSettingsService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return ValueListenableBuilder<Locale>(
      valueListenable: SettingsService.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        );
      },
    );
  }

  testWidgets('OnboardingScreen switches language when Tagalog is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Verify English (default)
    expect(find.text('Welcome to PH Fare Calculator'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);

    // 2. Tap Tagalog Button
    await tester.tap(find.text('Tagalog'));
    await tester.pumpAndSettle();

    // 3. Verify Tagalog Text
    // Note: Adjust expectations based on actual arb file content if different
    // Assuming standard translations:
    expect(
      find.text('Maligayang pagdating sa PH Fare Calculator'),
      findsOneWidget,
    );
    expect(find.text('Pumili ng Wika'), findsOneWidget);

    // 4. Tap English Button
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 5. Verify English again
    expect(find.text('Welcome to PH Fare Calculator'), findsOneWidget);
  });
}
