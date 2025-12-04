// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to PH Fare Calculator';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get continueButton => 'Continue';

  @override
  String get disclaimer =>
      'Disclaimer: All fare calculations are estimates only and may not reflect real-time prices.';

  @override
  String get fareEstimatorTitle => 'PH Fare Calculator';

  @override
  String get originLabel => 'Origin';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get calculateFareButton => 'Calculate Fare';

  @override
  String get saveRouteButton => 'Save Route';

  @override
  String get routeSavedMessage => 'Route saved to offline history!';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get provincialModeTitle => 'Provincial Mode';

  @override
  String get provincialModeSubtitle => 'Enable provincial fare rates';

  @override
  String get highContrastModeTitle => 'High Contrast Mode';

  @override
  String get highContrastModeSubtitle =>
      'Increase contrast for better visibility';

  @override
  String get trafficFactorTitle => 'Traffic Factor';

  @override
  String get trafficFactorSubtitle =>
      'Adjusts the fare calculation based on expected traffic conditions.';

  @override
  String get trafficLow => 'Low';

  @override
  String get trafficLowSubtitle => 'Light traffic';

  @override
  String get trafficMedium => 'Medium';

  @override
  String get trafficMediumSubtitle => 'Moderate traffic';

  @override
  String get trafficHigh => 'High';

  @override
  String get trafficHighSubtitle => 'Heavy traffic';
}
