import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_estimator/src/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_estimator/src/presentation/screens/settings_screen.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSettingsService mockSettingsService;

  setUp(() {
    mockSettingsService = MockSettingsService();
    
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SettingsService>()) getIt.unregister<SettingsService>();
    getIt.registerSingleton<SettingsService>(mockSettingsService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );
  }

  testWidgets('SettingsScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Provincial Mode'), findsOneWidget);
    expect(find.text('High Contrast Mode'), findsOneWidget);
    expect(find.text('Traffic Factor'), findsOneWidget);
  });

  testWidgets('Toggles update settings service', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Toggle Provincial Mode
    final provincialSwitch = find.widgetWithText(SwitchListTile, 'Provincial Mode');
    await tester.tap(provincialSwitch);
    await tester.pumpAndSettle();

    expect(mockSettingsService.provincialMode, true);

    // 2. Toggle High Contrast
    final highContrastSwitch = find.widgetWithText(SwitchListTile, 'High Contrast Mode');
    await tester.tap(highContrastSwitch);
    await tester.pumpAndSettle();

    expect(mockSettingsService.highContrast, true);
  });

  testWidgets('Traffic Factor selection updates settings service', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Select High Traffic
    final highTrafficRadio = find.widgetWithText(RadioListTile<TrafficFactor>, 'High');
    await tester.tap(highTrafficRadio);
    await tester.pumpAndSettle();

    expect(mockSettingsService.trafficFactor, TrafficFactor.high);
  });
}