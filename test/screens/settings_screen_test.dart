import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_calculator/src/l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/presentation/screens/settings_screen.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_map_service.dart';
import 'package:ph_fare_calculator/src/services/offline/offline_mode_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';


import '../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsService mockSettingsService;
  late MockFareRepository mockFareRepository;
  late MockOfflineModeService mockOfflineModeService;
  late MockOfflineMapService mockOfflineMapService;

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockFareRepository = MockFareRepository();
    mockOfflineModeService = MockOfflineModeService();
    mockOfflineMapService = MockOfflineMapService();

    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerSingleton<SettingsService>(mockSettingsService);
    getIt.registerSingleton<FareRepository>(mockFareRepository);
    getIt.registerSingleton<OfflineModeService>(mockOfflineModeService);
    getIt.registerSingleton<OfflineMapService>(mockOfflineMapService);
  });


  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: SettingsScreen(settingsService: mockSettingsService),
    );
  }

  testWidgets('SettingsScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    // Wait for localization and async _loadSettings to complete
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Provincial Mode'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Traffic Factor'), findsOneWidget);

    // Scroll down to see Passenger Type section
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Passenger Type'), findsOneWidget);

    // Scroll down more to see Transport Modes section
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Transport Modes'), findsOneWidget);
  });

  testWidgets('Toggles update settings service', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 1. Toggle Provincial Mode
    final provincialSwitch = find.widgetWithText(
      SwitchListTile,
      'Provincial Mode',
    );
    await tester.tap(provincialSwitch);
    await tester.pumpAndSettle();

    expect(mockSettingsService.provincialMode, true);
  });

  testWidgets('Theme mode selector updates settings service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Find and tap the Dark theme segment
    final darkSegment = find.text('Dark');
    await tester.tap(darkSegment);
    await tester.pumpAndSettle();

    expect(mockSettingsService.themeMode, 'dark');

    // Tap the Light theme segment
    final lightSegment = find.text('Light');
    await tester.tap(lightSegment);
    await tester.pumpAndSettle();

    expect(mockSettingsService.themeMode, 'light');
  });

  testWidgets('Traffic Factor selection updates settings service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Scroll to ensure the High traffic option is visible
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Select High Traffic
    final highTrafficRadio = find.widgetWithText(
      RadioListTile<TrafficFactor>,
      'High',
    );
    await tester.tap(highTrafficRadio);
    await tester.pumpAndSettle();

    expect(mockSettingsService.trafficFactor, TrafficFactor.high);
  });

  testWidgets('Transport modes are grouped by category', (
    WidgetTester tester,
  ) async {
    // Add formulas to mock so we can test category grouping
    mockFareRepository.formulasToReturn = [
      FareFormula(
        mode: 'Jeepney',
        subType: 'Traditional',
        baseFare: 13.0,
        perKmRate: 1.80,
      ),
    ];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Scroll down to see Transport Modes section (multiple scrolls needed)
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // The Phase 5 refactor groups modes by category (Road, Rail, Water)
    expect(find.text('Transport Modes'), findsOneWidget);
    // With Jeepney formula, we should see the Road category
    expect(find.text('Road'), findsOneWidget);
  });

  testWidgets('About section contains Source Code link to GitHub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Scroll down to see About section
    final sourceCodeFinder = find.text('Source Code');
    await tester.scrollUntilVisible(
      sourceCodeFinder,
      200.0,
    );
    await tester.pumpAndSettle();

    // Verify the Source Code tile exists
    expect(sourceCodeFinder, findsOneWidget);
    expect(find.text('View on GitHub'), findsOneWidget);
  });
}
