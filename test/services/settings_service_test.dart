import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:ph_fare_calculator/src/models/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsService settingsService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settingsService = SettingsService();
  });

  test('Default values are correct', () async {
    expect(await settingsService.getProvincialMode(), false);
    expect(await settingsService.getTrafficFactor(), TrafficFactor.medium);
    // Default theme is 'light' for first-time users (changed from 'system')
    expect(await settingsService.getThemeMode(), 'light');
  });

  test('Provincial mode is saved and retrieved', () async {
    await settingsService.setProvincialMode(true);
    expect(await settingsService.getProvincialMode(), true);

    await settingsService.setProvincialMode(false);
    expect(await settingsService.getProvincialMode(), false);
  });

  test('Traffic factor is saved and retrieved', () async {
    await settingsService.setTrafficFactor(TrafficFactor.high);
    expect(await settingsService.getTrafficFactor(), TrafficFactor.high);

    await settingsService.setTrafficFactor(TrafficFactor.low);
    expect(await settingsService.getTrafficFactor(), TrafficFactor.low);
  });

  test('Theme mode is saved and retrieved', () async {
    await settingsService.setThemeMode('dark');
    expect(await settingsService.getThemeMode(), 'dark');
    expect(SettingsService.themeModeNotifier.value, 'dark');

    await settingsService.setThemeMode('light');
    expect(await settingsService.getThemeMode(), 'light');
    expect(SettingsService.themeModeNotifier.value, 'light');

    await settingsService.setThemeMode('system');
    expect(await settingsService.getThemeMode(), 'system');
    expect(SettingsService.themeModeNotifier.value, 'system');
  });

  test('Invalid theme mode defaults to system', () async {
    await settingsService.setThemeMode('invalid');
    expect(await settingsService.getThemeMode(), 'system');
  });

  test('Last location returns null when not previously saved', () async {
    final location = await settingsService.getLastLocation();
    expect(location, isNull);
  });

  test('Last location is saved and retrieved correctly', () async {
    final testLocation = Location(
      name: 'Test Location',
      latitude: 14.5995,
      longitude: 120.9842,
    );

    await settingsService.saveLastLocation(testLocation);
    final retrieved = await settingsService.getLastLocation();

    expect(retrieved, isNotNull);
    expect(retrieved!.name, 'Test Location');
    expect(retrieved.latitude, 14.5995);
    expect(retrieved.longitude, 120.9842);
  });

  test('Last location can be overwritten', () async {
    final location1 = Location(
      name: 'First Location',
      latitude: 14.5995,
      longitude: 120.9842,
    );

    final location2 = Location(
      name: 'Second Location',
      latitude: 10.3157,
      longitude: 123.8854,
    );

    await settingsService.saveLastLocation(location1);
    await settingsService.saveLastLocation(location2);

    final retrieved = await settingsService.getLastLocation();
    expect(retrieved!.name, 'Second Location');
    expect(retrieved.latitude, 10.3157);
    expect(retrieved.longitude, 123.8854);
  });
}
