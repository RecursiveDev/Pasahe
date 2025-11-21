import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ph_fare_estimator/main.dart';
import 'package:ph_fare_estimator/src/models/fare_formula.dart';
import 'package:ph_fare_estimator/src/models/fare_result.dart';
import 'package:ph_fare_estimator/src/models/saved_route.dart';
import 'package:ph_fare_estimator/src/presentation/screens/main_screen.dart';
import 'package:ph_fare_estimator/src/presentation/screens/onboarding_screen.dart';
import 'package:ph_fare_estimator/src/presentation/screens/splash_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Setup Hive for MainScreen to not crash if it gets built
    tempDir = await Directory.systemTemp.createTemp('hive_test_onboarding_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FareFormulaAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SavedRouteAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FareResultAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(IndicatorLevelAdapter());
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Shows SplashScreen when onboarding is not completed',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(hasCompletedOnboarding: false));

    expect(find.byType(SplashScreen), findsOneWidget);
    
    // Handle the Future.delayed navigation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('SplashScreen navigates to OnboardingScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    
    expect(find.byType(FlutterLogo), findsOneWidget);

    // Wait for 2 seconds delay
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Shows MainScreen when onboarding is completed',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(hasCompletedOnboarding: true));

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}