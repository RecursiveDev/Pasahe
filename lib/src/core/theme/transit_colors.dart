import 'package:flutter/material.dart';

/// Theme extension for transit line colors that adapt to light/dark mode.
/// These semantic colors ensure proper contrast and accessibility in both themes.
@immutable
class TransitColors extends ThemeExtension<TransitColors> {
  const TransitColors({
    required this.lrt1,
    required this.lrt2,
    required this.mrt3,
    required this.mrt7,
    required this.pnr,
    required this.jeep,
    required this.bus,
    required this.discountStudent,
    required this.discountSenior,
    required this.discountPwd,
    required this.discountBadge,
    required this.discountBadgeText,
    required this.successColor,
    required this.onSuccessColor,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.originMarker,
    required this.onOriginMarker,
    required this.standardFare,
  });

  /// LRT-1 Line color (Green)
  final Color lrt1;

  /// LRT-2 Line color (Purple)
  final Color lrt2;

  /// MRT-3 Line color (Blue)
  final Color mrt3;

  /// MRT-7 Line color (Orange)
  final Color mrt7;

  /// PNR Line color (Brown)
  final Color pnr;

  /// Jeepney route color (Teal)
  final Color jeep;

  /// Bus route color (Red)
  final Color bus;

  /// Student discount card color
  final Color discountStudent;

  /// Senior citizen discount card color
  final Color discountSenior;

  /// PWD discount card color
  final Color discountPwd;

  /// Discount badge background color
  final Color discountBadge;

  /// Discount badge text color
  final Color discountBadgeText;

  /// Success/positive status color (e.g., downloaded, completed)
  final Color successColor;

  /// Text/icon color on success color
  final Color onSuccessColor;

  /// Success container/background color
  final Color successContainer;

  /// Text/icon color on success container
  final Color onSuccessContainer;

  /// Origin marker color on maps
  final Color originMarker;

  /// Icon color on origin marker
  final Color onOriginMarker;

  /// Standard fare indicator color
  final Color standardFare;

  @override
  TransitColors copyWith({
    Color? lrt1,
    Color? lrt2,
    Color? mrt3,
    Color? mrt7,
    Color? pnr,
    Color? jeep,
    Color? bus,
    Color? discountStudent,
    Color? discountSenior,
    Color? discountPwd,
    Color? discountBadge,
    Color? discountBadgeText,
    Color? successColor,
    Color? onSuccessColor,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? originMarker,
    Color? onOriginMarker,
    Color? standardFare,
  }) {
    return TransitColors(
      lrt1: lrt1 ?? this.lrt1,
      lrt2: lrt2 ?? this.lrt2,
      mrt3: mrt3 ?? this.mrt3,
      mrt7: mrt7 ?? this.mrt7,
      pnr: pnr ?? this.pnr,
      jeep: jeep ?? this.jeep,
      bus: bus ?? this.bus,
      discountStudent: discountStudent ?? this.discountStudent,
      discountSenior: discountSenior ?? this.discountSenior,
      discountPwd: discountPwd ?? this.discountPwd,
      discountBadge: discountBadge ?? this.discountBadge,
      discountBadgeText: discountBadgeText ?? this.discountBadgeText,
      successColor: successColor ?? this.successColor,
      onSuccessColor: onSuccessColor ?? this.onSuccessColor,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      originMarker: originMarker ?? this.originMarker,
      onOriginMarker: onOriginMarker ?? this.onOriginMarker,
      standardFare: standardFare ?? this.standardFare,
    );
  }

  @override
  TransitColors lerp(ThemeExtension<TransitColors>? other, double t) {
    if (other is! TransitColors) {
      return this;
    }
    return TransitColors(
      lrt1: Color.lerp(lrt1, other.lrt1, t)!,
      lrt2: Color.lerp(lrt2, other.lrt2, t)!,
      mrt3: Color.lerp(mrt3, other.mrt3, t)!,
      mrt7: Color.lerp(mrt7, other.mrt7, t)!,
      pnr: Color.lerp(pnr, other.pnr, t)!,
      jeep: Color.lerp(jeep, other.jeep, t)!,
      bus: Color.lerp(bus, other.bus, t)!,
      discountStudent: Color.lerp(discountStudent, other.discountStudent, t)!,
      discountSenior: Color.lerp(discountSenior, other.discountSenior, t)!,
      discountPwd: Color.lerp(discountPwd, other.discountPwd, t)!,
      discountBadge: Color.lerp(discountBadge, other.discountBadge, t)!,
      discountBadgeText: Color.lerp(
        discountBadgeText,
        other.discountBadgeText,
        t,
      )!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      onSuccessColor: Color.lerp(onSuccessColor, other.onSuccessColor, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      originMarker: Color.lerp(originMarker, other.originMarker, t)!,
      onOriginMarker: Color.lerp(onOriginMarker, other.onOriginMarker, t)!,
      standardFare: Color.lerp(standardFare, other.standardFare, t)!,
    );
  }

  /// Light mode transit colors - saturated for visibility on light backgrounds
  /// Colors adjusted to meet WCAG AA 3:1 minimum contrast ratio on white/light surfaces
  static const light = TransitColors(
    lrt1: Color(
      0xFF2E7D32,
    ), // Darker Green - 4.52:1 on white (was #4CAF50 at 2.78:1)
    lrt2: Color(0xFF7B1FA2), // Purple - passes
    mrt3: Color(
      0xFF1565C0,
    ), // Darker Blue - 4.62:1 on white (was #2196F3 at 2.72:1)
    mrt7: Color(
      0xFFE65100,
    ), // Darker Orange - 3.26:1 on white (was #FF9800 at 2.16:1)
    pnr: Color(0xFF795548), // Brown - passes
    jeep: Color(0xFF00695C), // Teal - passes
    bus: Color(0xFFC62828), // Red - passes
    discountStudent: Color(0xFF1976D2), // Blue - passes
    discountSenior: Color(0xFF7B1FA2), // Purple - passes
    discountPwd: Color(0xFF388E3C), // Green - passes
    discountBadge: Color(
      0xFFA5D6A7,
    ), // Lighter pastel green for better text contrast
    discountBadgeText: Color(0xFF1B5E20), // Dark Green - 5.24:1 on #A5D6A7
    // Semantic status colors
    successColor: Color(0xFF2E7D32), // Same as lrt1 green - passes WCAG
    onSuccessColor: Color(0xFFFFFFFF), // White on green
    successContainer: Color(0xFFC8E6C9), // Light green container
    onSuccessContainer: Color(0xFF1B5E20), // Dark green text
    originMarker: Color(0xFF2E7D32), // Green origin marker
    onOriginMarker: Color(0xFFFFFFFF), // White icon on marker
    standardFare: Color(0xFF2E7D32), // Green for standard fare indicator
  );

  /// Dark mode transit colors - highly desaturated/pastel for M3 dark mode
  /// These colors are significantly muted to avoid eye strain on the
  /// #141218 dark background and follow M3 tonal principles.
  static const dark = TransitColors(
    lrt1: Color(0xFFA8D5AA), // Desaturated pastel green
    lrt2: Color(0xFFD4B8E0), // Desaturated pastel purple
    mrt3: Color(0xFFABC8E8), // Desaturated pastel blue
    mrt7: Color(0xFFE8CFA8), // Desaturated pastel orange
    pnr: Color(0xFFC4B5AD), // Desaturated pastel brown
    jeep: Color(0xFF9DCDC6), // Desaturated pastel teal
    bus: Color(0xFFE8AEAB), // Desaturated pastel red
    discountStudent: Color(0xFFABC8E8), // Desaturated pastel blue
    discountSenior: Color(0xFFD4B8E0), // Desaturated pastel purple
    discountPwd: Color(0xFFA8D5AA), // Desaturated pastel green
    discountBadge: Color(0xFFA8D5AA), // Desaturated pastel green
    discountBadgeText: Color(0xFF1B3D1D), // Dark green for contrast on pastel
    // Semantic status colors for dark mode
    successColor: Color(0xFFA8D5AA), // Pastel green for dark mode
    onSuccessColor: Color(0xFF1B3D1D), // Dark green on pastel
    successContainer: Color(0xFF1B3D1D), // Dark green container
    onSuccessContainer: Color(0xFFA8D5AA), // Pastel green text
    originMarker: Color(0xFFA8D5AA), // Pastel green origin marker
    onOriginMarker: Color(0xFF1B3D1D), // Dark icon on marker
    standardFare: Color(0xFFA8D5AA), // Pastel green for standard fare
  );
}
