// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get welcomeTitle => 'Maligayang pagdating sa PH Fare Calculator';

  @override
  String get selectLanguage => 'Pumili ng Wika';

  @override
  String get continueButton => 'Magpatuloy';

  @override
  String get disclaimer =>
      'Paunawa: Ang lahat ng kalkulasyon ng pamasahe ay mga taya lamang at maaaring hindi sumasalamin sa kasalukuyang presyo.';

  @override
  String get fareEstimatorTitle => 'PH Fare Calculator';

  @override
  String get originLabel => 'Pinagmulan';

  @override
  String get destinationLabel => 'Destinasyon';

  @override
  String get calculateFareButton => 'Kalkulahin ang Pamasahe';

  @override
  String get saveRouteButton => 'I-save ang Ruta';

  @override
  String get routeSavedMessage => 'Na-save na ang ruta sa offline history!';

  @override
  String get settingsTitle => 'Mga Setting';

  @override
  String get provincialModeTitle => 'Provincial Mode';

  @override
  String get provincialModeSubtitle =>
      'Paganahin ang mga presyo ng pamasahe sa probinsya';

  @override
  String get highContrastModeTitle => 'High Contrast Mode';

  @override
  String get highContrastModeSubtitle =>
      'Taasan ang contrast para sa mas malinaw na pagtingin';

  @override
  String get trafficFactorTitle => 'Antas ng Trapiko';

  @override
  String get trafficFactorSubtitle =>
      'Isinasaayos ang kalkulasyon ng pamasahe batay sa inaasahang kondisyon ng trapiko.';

  @override
  String get trafficLow => 'Mababa';

  @override
  String get trafficLowSubtitle => 'Maluwag na trapiko';

  @override
  String get trafficMedium => 'Katamtaman';

  @override
  String get trafficMediumSubtitle => 'Katamtamang trapiko';

  @override
  String get trafficHigh => 'Mataas';

  @override
  String get trafficHighSubtitle => 'Mabigat na trapiko';
}
