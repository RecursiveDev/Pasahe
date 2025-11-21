import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';
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
    expect(await settingsService.getHighContrastEnabled(), false);
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

  test('High contrast is saved and retrieved', () async {
    await settingsService.setHighContrastEnabled(true);
    expect(await settingsService.getHighContrastEnabled(), true);
    expect(SettingsService.highContrastNotifier.value, true);
  });
}
