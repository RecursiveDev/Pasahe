// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

void main() {
  // 1. Default M3 Light Scheme (Baseline Purple)
  // When useMaterial3 is true, and no colorScheme is provided, Flutter uses a default purple scheme.
  final ThemeData themeLight = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );
  final ColorScheme defaultLight = themeLight.colorScheme;

  final ThemeData themeDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  );
  final ColorScheme defaultDark = themeDark.colorScheme;

  print('--- Flutter Default M3 Light Scheme (useMaterial3: true) ---');
  _printScheme(defaultLight);

  print('\n--- Flutter Default M3 Dark Scheme (useMaterial3: true) ---');
  _printScheme(defaultDark);
}

void _printScheme(ColorScheme scheme) {
  print('| Property | Hex |');
  print('|---|---|');
  print('| primary | ${_toHex(scheme.primary)} |');
  print('| onPrimary | ${_toHex(scheme.onPrimary)} |');
  print('| primaryContainer | ${_toHex(scheme.primaryContainer)} |');
  print('| onPrimaryContainer | ${_toHex(scheme.onPrimaryContainer)} |');
  print('| secondary | ${_toHex(scheme.secondary)} |');
  print('| onSecondary | ${_toHex(scheme.onSecondary)} |');
  print('| secondaryContainer | ${_toHex(scheme.secondaryContainer)} |');
  print('| onSecondaryContainer | ${_toHex(scheme.onSecondaryContainer)} |');
  print('| tertiary | ${_toHex(scheme.tertiary)} |');
  print('| onTertiary | ${_toHex(scheme.onTertiary)} |');
  print('| tertiaryContainer | ${_toHex(scheme.tertiaryContainer)} |');
  print('| onTertiaryContainer | ${_toHex(scheme.onTertiaryContainer)} |');
  print('| error | ${_toHex(scheme.error)} |');
  print('| onError | ${_toHex(scheme.onError)} |');
  print('| errorContainer | ${_toHex(scheme.errorContainer)} |');
  print('| onErrorContainer | ${_toHex(scheme.onErrorContainer)} |');
  print('| background | ${_toHex(scheme.surface)} |');
  print('| onBackground | ${_toHex(scheme.onSurface)} |');
  print('| surface | ${_toHex(scheme.surface)} |');
  print('| onSurface | ${_toHex(scheme.onSurface)} |');
  print('| surfaceVariant | ${_toHex(scheme.surfaceContainerHighest)} |');
  print('| onSurfaceVariant | ${_toHex(scheme.onSurfaceVariant)} |');
  print('| outline | ${_toHex(scheme.outline)} |');
  print('| outlineVariant | ${_toHex(scheme.outlineVariant)} |');
  print('| shadow | ${_toHex(scheme.shadow)} |');
  print('| scrim | ${_toHex(scheme.scrim)} |');
  print('| inverseSurface | ${_toHex(scheme.inverseSurface)} |');
  print('| onInverseSurface | ${_toHex(scheme.onInverseSurface)} |');
  print('| inversePrimary | ${_toHex(scheme.inversePrimary)} |');
  print('| surfaceTint | ${_toHex(scheme.surfaceTint)} |');
  // New M3 properties in recent Flutter versions
  try {
    // accessing these via dynamic to avoid compilation errors if running on older Flutter versions
    // though for this task we assume a reasonably recent one.
    // But let's stick to the standard ones first.
    // We can check surfaceContainer properties if available.
  } catch (e) {
    // Intentionally empty - we're just checking if the properties exist
  }
}

String _toHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
}
