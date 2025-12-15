import 'package:flutter/material.dart';

/// Size variants for the app logo widget.
enum AppLogoSize {
  /// Small size for app bar (40x40 outer, 28x28 inner, 16px icon)
  small,

  /// Medium size for general use (80x80 outer, 56x56 inner, 32px icon)
  medium,

  /// Large size for splash/onboarding (140x140 outer, 100x100 inner, 56px icon)
  large,
}

/// A reusable logo widget that displays the PH Fare Calculator bus icon
/// with a circular gradient container matching the splash/onboarding screens.
///
/// The widget supports different sizes through [AppLogoSize] and maintains
/// consistent proportions and styling across all sizes.
class AppLogoWidget extends StatelessWidget {
  /// Creates an [AppLogoWidget] with the specified size.
  const AppLogoWidget({
    super.key,
    this.size = AppLogoSize.large,
    this.showShadow = true,
  });

  /// The size variant of the logo.
  final AppLogoSize size;

  /// Whether to show the drop shadow. Defaults to true.
  final bool showShadow;

  /// Brand color from AppTheme - Philippine flag blue.
  static const Color _primaryBlue = Color(0xFF0038A8);

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();

    return Semantics(
      label: 'PH Fare Calculator logo',
      child: Container(
        width: dimensions.outerSize,
        height: dimensions.outerSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: dimensions.shadowBlur,
                    offset: Offset(0, dimensions.shadowOffset),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: dimensions.innerSize,
            height: dimensions.innerSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryBlue, _primaryBlue.withValues(alpha: 0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.directions_bus_rounded,
                size: dimensions.iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _LogoDimensions _getDimensions() {
    switch (size) {
      case AppLogoSize.small:
        return const _LogoDimensions(
          outerSize: 40,
          innerSize: 28,
          iconSize: 16,
          shadowBlur: 8,
          shadowOffset: 2,
        );
      case AppLogoSize.medium:
        return const _LogoDimensions(
          outerSize: 80,
          innerSize: 56,
          iconSize: 32,
          shadowBlur: 16,
          shadowOffset: 4,
        );
      case AppLogoSize.large:
        return const _LogoDimensions(
          outerSize: 140,
          innerSize: 100,
          iconSize: 56,
          shadowBlur: 24,
          shadowOffset: 8,
        );
    }
  }
}

/// Internal class to hold dimension values for each size variant.
class _LogoDimensions {
  const _LogoDimensions({
    required this.outerSize,
    required this.innerSize,
    required this.iconSize,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final double outerSize;
  final double innerSize;
  final double iconSize;
  final double shadowBlur;
  final double shadowOffset;
}
