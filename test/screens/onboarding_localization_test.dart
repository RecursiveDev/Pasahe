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

  String themeMode = 'system';
  @override
  Future<String> getThemeMode() async => themeMode;
  @override
  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
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
    // Use a larger screen size to avoid overflow issues
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Verify first page shows welcome title
    expect(find.text('Welcome to PH Fare Calculator'), findsOneWidget);

    // 2. Navigate to the language selection page (page 3) by tapping Next button twice
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Now on page 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 3. Verify we're on the language selection page (page 3)
    expect(find.text('Choose Your Language'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);

    // 4. Tap Tagalog Card
    await tester.tap(find.text('Tagalog'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // 5. Verify the language changed to Tagalog
    // Note: "Pumili ng Wika" appears twice - once for title ("Choose Your Language")
    // and once for description ("Select Language") - both translate to same text
    expect(find.text('Pumili ng Wika'), findsAtLeastNWidgets(1));

    // 6. Tap English Card
    await tester.tap(find.text('English'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // 7. Verify English again
    expect(find.text('Choose Your Language'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);
  });
}
