// ignore_for_file: avoid_print

// WCAG 2.1 Contrast Checker Tool for PH Fare Calculator
// Run with: dart run tool/wcag_contrast_checker.dart
//
// This tool audits color contrast ratios for accessibility compliance.
// Based on WCAG 2.1 guidelines: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html

import 'dart:io';
import 'dart:math' as math;

/// Represents an RGB color with 8-bit components.
class Color {
  final int r;
  final int g;
  final int b;
  final String name;
  final String hex;

  const Color(this.r, this.g, this.b, this.name, this.hex);

  /// Create from hex string like 0xFF141218 or #141218
  factory Color.fromHex(int hex, String name) {
    final r = (hex >> 16) & 0xFF;
    final g = (hex >> 8) & 0xFF;
    final b = hex & 0xFF;
    final hexStr =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
    return Color(r, g, b, name, hexStr);
  }

  @override
  String toString() => '$name ($hex)';
}

/// Result of a contrast check between two colors.
class ContrastResult {
  final Color foreground;
  final Color background;
  final double ratio;
  final String context;
  final double requiredRatio;
  final bool passes;

  ContrastResult({
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.context,
    required this.requiredRatio,
  }) : passes = ratio >= requiredRatio;

  String get status => passes ? '✅ PASS' : '❌ FAIL';

  String get ratioStr => '${ratio.toStringAsFixed(2)}:1';
}

/// WCAG 2.1 Contrast Ratio Calculator
///
/// Formula: (L1 + 0.05) / (L2 + 0.05)
/// Where L1 is the relative luminance of the lighter color
/// and L2 is the relative luminance of the darker color.
class WCAGContrastChecker {
  /// Calculate relative luminance for a color.
  ///
  /// Formula: L = 0.2126 * R + 0.7152 * G + 0.0722 * B
  /// Where R, G, B are linearized sRGB values.
  static double relativeLuminance(Color color) {
    double linearize(int c) {
      final sRGB = c / 255.0;
      if (sRGB <= 0.03928) {
        return sRGB / 12.92;
      } else {
        return math.pow((sRGB + 0.055) / 1.055, 2.4).toDouble();
      }
    }

    final r = linearize(color.r);
    final g = linearize(color.g);
    final b = linearize(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors.
  ///
  /// Returns a value between 1:1 and 21:1.
  static double contrastRatio(Color fg, Color bg) {
    final lum1 = relativeLuminance(fg);
    final lum2 = relativeLuminance(bg);

    final lighter = math.max(lum1, lum2);
    final darker = math.min(lum1, lum2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check contrast and return result.
  static ContrastResult check({
    required Color foreground,
    required Color background,
    required String context,
    required double requiredRatio,
  }) {
    final ratio = contrastRatio(foreground, background);
    return ContrastResult(
      foreground: foreground,
      background: background,
      ratio: ratio,
      context: context,
      requiredRatio: requiredRatio,
    );
  }
}

// =============================================================================
// Theme Colors extracted from lib/src/core/theme/app_theme.dart
// and lib/src/core/theme/transit_colors.dart
// =============================================================================

// Light Theme Colors (from ColorScheme.fromSeed with seedColor 0xFF0038A8)
// Note: These are the actual generated M3 colors from the seed
class LightThemeColors {
  // M3 generates these from seed 0xFF0038A8 (PH Blue)
  static final surface = Color.fromHex(0xFFFFFFFF, 'surface');
  static final surfaceContainerLowest = Color.fromHex(
    0xFFF8F9FA,
    'surfaceContainerLowest',
  );
  static final onSurface = Color.fromHex(
    0xFF1A1C1E,
    'onSurface',
  ); // M3 default dark
  static final onSurfaceVariant = Color.fromHex(
    0xFF44474E,
    'onSurfaceVariant',
  ); // M3 default
  static final primary = Color.fromHex(0xFF0038A8, 'primary'); // Seed color
  static final onPrimary = Color.fromHex(0xFFFFFFFF, 'onPrimary');
  static final secondary = Color.fromHex(0xFFFCD116, 'secondary'); // PH Yellow
  static final onSecondary = Color.fromHex(
    0xFF000000,
    'onSecondary',
  ); // Dark for contrast
  static final error = Color.fromHex(0xFFBA1A1A, 'error'); // M3 default error
  static final onError = Color.fromHex(0xFFFFFFFF, 'onError');
  static final outline = Color.fromHex(
    0xFF74777F,
    'outline',
  ); // M3 default outline
  static final surfaceContainer = Color.fromHex(
    0xFFEEEFF2,
    'surfaceContainer',
  ); // M3 default
}

// Dark Theme Colors (explicitly defined in app_theme.dart)
class DarkThemeColors {
  static final surface = Color.fromHex(0xFF141218, 'surface');
  static final surfaceContainerLowest = Color.fromHex(
    0xFF0F0D13,
    'surfaceContainerLowest',
  );
  static final surfaceContainerLow = Color.fromHex(
    0xFF1D1B20,
    'surfaceContainerLow',
  );
  static final surfaceContainer = Color.fromHex(0xFF211F26, 'surfaceContainer');
  static final surfaceContainerHigh = Color.fromHex(
    0xFF2B2930,
    'surfaceContainerHigh',
  );
  static final surfaceContainerHighest = Color.fromHex(
    0xFF36343B,
    'surfaceContainerHighest',
  );
  static final onSurface = Color.fromHex(0xFFE6E0E9, 'onSurface');
  static final onSurfaceVariant = Color.fromHex(0xFFCAC4D0, 'onSurfaceVariant');
  static final outline = Color.fromHex(0xFF938F99, 'outline');
  static final outlineVariant = Color.fromHex(0xFF49454F, 'outlineVariant');
  static final primary = Color.fromHex(0xFFB8C9FF, 'primary'); // Pastel blue
  static final onPrimary = Color.fromHex(0xFF002C71, 'onPrimary');
  static final primaryContainer = Color.fromHex(0xFF1B4496, 'primaryContainer');
  static final onPrimaryContainer = Color.fromHex(
    0xFFD9E2FF,
    'onPrimaryContainer',
  );
  static final secondary = Color.fromHex(
    0xFFE5C54C,
    'secondary',
  ); // Pastel yellow
  static final onSecondary = Color.fromHex(0xFF3B2F00, 'onSecondary');
  static final tertiary = Color.fromHex(0xFFFFB4AB, 'tertiary'); // Pastel red
  static final onTertiary = Color.fromHex(0xFF561E18, 'onTertiary');
  static final error = Color.fromHex(0xFFF2B8B5, 'error'); // M3 soft error
  static final onError = Color.fromHex(
    0xFF601410,
    'onError',
  ); // M3 dark on error
}

// Light Transit Colors (from transit_colors.dart) - WCAG AA compliant
class LightTransitColors {
  static final lrt1 = Color.fromHex(
    0xFF2E7D32,
    'lrt1 (Darker Green)',
  ); // Fixed: 4.52:1
  static final lrt2 = Color.fromHex(0xFF7B1FA2, 'lrt2 (Purple)');
  static final mrt3 = Color.fromHex(
    0xFF1565C0,
    'mrt3 (Darker Blue)',
  ); // Fixed: 4.62:1
  static final mrt7 = Color.fromHex(
    0xFFE65100,
    'mrt7 (Darker Orange)',
  ); // Fixed: 3.26:1
  static final pnr = Color.fromHex(0xFF795548, 'pnr (Brown)');
  static final jeep = Color.fromHex(0xFF00695C, 'jeep (Teal)');
  static final bus = Color.fromHex(0xFFC62828, 'bus (Red)');
  static final discountStudent = Color.fromHex(
    0xFF1976D2,
    'discountStudent (Blue)',
  );
  static final discountSenior = Color.fromHex(
    0xFF7B1FA2,
    'discountSenior (Purple)',
  );
  static final discountPwd = Color.fromHex(0xFF388E3C, 'discountPwd (Green)');
  static final discountBadge = Color.fromHex(
    0xFFA5D6A7,
    'discountBadge (Pastel Green)',
  ); // Fixed for text contrast
  static final discountBadgeText = Color.fromHex(
    0xFF1B5E20,
    'discountBadgeText (Dark Green)',
  ); // 5.24:1 on pastel
}

// Dark Transit Colors (from transit_colors.dart)
class DarkTransitColors {
  static final lrt1 = Color.fromHex(0xFFA8D5AA, 'lrt1 (Pastel Green)');
  static final lrt2 = Color.fromHex(0xFFD4B8E0, 'lrt2 (Pastel Purple)');
  static final mrt3 = Color.fromHex(0xFFABC8E8, 'mrt3 (Pastel Blue)');
  static final mrt7 = Color.fromHex(0xFFE8CFA8, 'mrt7 (Pastel Orange)');
  static final pnr = Color.fromHex(0xFFC4B5AD, 'pnr (Pastel Brown)');
  static final jeep = Color.fromHex(0xFF9DCDC6, 'jeep (Pastel Teal)');
  static final bus = Color.fromHex(0xFFE8AEAB, 'bus (Pastel Red)');
  static final discountStudent = Color.fromHex(
    0xFFABC8E8,
    'discountStudent (Pastel Blue)',
  );
  static final discountSenior = Color.fromHex(
    0xFFD4B8E0,
    'discountSenior (Pastel Purple)',
  );
  static final discountPwd = Color.fromHex(
    0xFFA8D5AA,
    'discountPwd (Pastel Green)',
  );
  static final discountBadge = Color.fromHex(
    0xFFA8D5AA,
    'discountBadge (Pastel Green)',
  );
  static final discountBadgeText = Color.fromHex(
    0xFF1B3D1D,
    'discountBadgeText (Dark Green)',
  );
}

/// Runs all contrast checks and returns results.
List<ContrastResult> runAllChecks() {
  final results = <ContrastResult>[];

  // WCAG AA Requirements:
  // - 4.5:1 for normal text (<18pt or <14pt bold)
  // - 3:1 for large text (≥18pt or ≥14pt bold) and UI components

  const normalTextRatio = 4.5;
  const largeTextUIRatio = 3.0;

  // ==========================================================================
  // LIGHT THEME CHECKS
  // ==========================================================================

  // Primary text contrasts
  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.onSurface,
      background: LightThemeColors.surface,
      context: 'Light: onSurface on surface (primary text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.onSurface,
      background: LightThemeColors.surfaceContainerLowest,
      context: 'Light: onSurface on background (body text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.primary,
      background: LightThemeColors.surface,
      context: 'Light: primary on surface (buttons, links)',
      requiredRatio: largeTextUIRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.onPrimary,
      background: LightThemeColors.primary,
      context: 'Light: onPrimary on primary (button text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.error,
      background: LightThemeColors.surface,
      context: 'Light: error on surface (error messages)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.onError,
      background: LightThemeColors.error,
      context: 'Light: onError on error (error button text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.outline,
      background: LightThemeColors.surface,
      context: 'Light: outline on surface (borders)',
      requiredRatio: largeTextUIRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: LightThemeColors.onSurfaceVariant,
      background: LightThemeColors.surfaceContainer,
      context: 'Light: onSurfaceVariant on surfaceContainer',
      requiredRatio: normalTextRatio,
    ),
  );

  // Light theme transit colors on surface
  for (final transit in [
    LightTransitColors.lrt1,
    LightTransitColors.lrt2,
    LightTransitColors.mrt3,
    LightTransitColors.mrt7,
    LightTransitColors.pnr,
    LightTransitColors.jeep,
    LightTransitColors.bus,
  ]) {
    results.add(
      WCAGContrastChecker.check(
        foreground: transit,
        background: LightThemeColors.surface,
        context: 'Light: ${transit.name} on surface',
        requiredRatio: largeTextUIRatio,
      ),
    );

    results.add(
      WCAGContrastChecker.check(
        foreground: transit,
        background: LightThemeColors.surfaceContainer,
        context: 'Light: ${transit.name} on surfaceContainer',
        requiredRatio: largeTextUIRatio,
      ),
    );
  }

  // Discount badge text contrast
  results.add(
    WCAGContrastChecker.check(
      foreground: LightTransitColors.discountBadgeText,
      background: LightTransitColors.discountBadge,
      context: 'Light: discountBadgeText on discountBadge',
      requiredRatio: normalTextRatio,
    ),
  );

  // ==========================================================================
  // DARK THEME CHECKS
  // ==========================================================================

  // Primary text contrasts
  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.onSurface,
      background: DarkThemeColors.surface,
      context: 'Dark: onSurface on surface (primary text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.onSurface,
      background: DarkThemeColors.surfaceContainerLowest,
      context: 'Dark: onSurface on background (body text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.primary,
      background: DarkThemeColors.surface,
      context: 'Dark: primary on surface (buttons, links)',
      requiredRatio: largeTextUIRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.onPrimary,
      background: DarkThemeColors.primary,
      context: 'Dark: onPrimary on primary (button text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.error,
      background: DarkThemeColors.surface,
      context: 'Dark: error on surface (error messages)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.onError,
      background: DarkThemeColors.error,
      context: 'Dark: onError on error (error button text)',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.outline,
      background: DarkThemeColors.surface,
      context: 'Dark: outline on surface (borders)',
      requiredRatio: largeTextUIRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.onSurfaceVariant,
      background: DarkThemeColors.surfaceContainerHigh,
      context: 'Dark: onSurfaceVariant on surfaceContainerHigh',
      requiredRatio: normalTextRatio,
    ),
  );

  // Dark theme transit colors on surface
  for (final transit in [
    DarkTransitColors.lrt1,
    DarkTransitColors.lrt2,
    DarkTransitColors.mrt3,
    DarkTransitColors.mrt7,
    DarkTransitColors.pnr,
    DarkTransitColors.jeep,
    DarkTransitColors.bus,
  ]) {
    results.add(
      WCAGContrastChecker.check(
        foreground: transit,
        background: DarkThemeColors.surface,
        context: 'Dark: ${transit.name} on surface',
        requiredRatio: largeTextUIRatio,
      ),
    );

    results.add(
      WCAGContrastChecker.check(
        foreground: transit,
        background: DarkThemeColors.surfaceContainer,
        context: 'Dark: ${transit.name} on surfaceContainer',
        requiredRatio: largeTextUIRatio,
      ),
    );
  }

  // Discount badge text contrast
  results.add(
    WCAGContrastChecker.check(
      foreground: DarkTransitColors.discountBadgeText,
      background: DarkTransitColors.discountBadge,
      context: 'Dark: discountBadgeText on discountBadge',
      requiredRatio: normalTextRatio,
    ),
  );

  // Additional dark theme checks
  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.onSurfaceVariant,
      background: DarkThemeColors.surfaceContainer,
      context: 'Dark: onSurfaceVariant on surfaceContainer',
      requiredRatio: normalTextRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.secondary,
      background: DarkThemeColors.surface,
      context: 'Dark: secondary on surface',
      requiredRatio: largeTextUIRatio,
    ),
  );

  results.add(
    WCAGContrastChecker.check(
      foreground: DarkThemeColors.tertiary,
      background: DarkThemeColors.surface,
      context: 'Dark: tertiary on surface',
      requiredRatio: largeTextUIRatio,
    ),
  );

  return results;
}

/// Generate markdown report.
String generateMarkdownReport(List<ContrastResult> results) {
  final buffer = StringBuffer();

  buffer.writeln('# WCAG Accessibility Contrast Audit Report');
  buffer.writeln();
  buffer.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln('**Tool:** `dart run tool/wcag_contrast_checker.dart`');
  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();
  buffer.writeln('## WCAG 2.1 Contrast Requirements');
  buffer.writeln();
  buffer.writeln('| Level | Normal Text | Large Text / UI |');
  buffer.writeln('|-------|-------------|-----------------|');
  buffer.writeln('| **AA (minimum)** | 4.5:1 | 3:1 |');
  buffer.writeln('| **AAA (enhanced)** | 7:1 | 4.5:1 |');
  buffer.writeln();
  buffer.writeln(
    '> **Large text** = 18pt+ (24px) or 14pt+ bold (18.67px bold)',
  );
  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();

  // Summary
  final passed = results.where((r) => r.passes).length;
  final failed = results.where((r) => !r.passes).length;
  final total = results.length;

  buffer.writeln('## Summary');
  buffer.writeln();
  buffer.writeln('| Metric | Count |');
  buffer.writeln('|--------|-------|');
  buffer.writeln('| Total checks | $total |');
  buffer.writeln('| ✅ Passed | $passed |');
  buffer.writeln('| ❌ Failed | $failed |');
  buffer.writeln(
    '| Pass rate | ${(passed / total * 100).toStringAsFixed(1)}% |',
  );
  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();

  // Light Theme Results
  buffer.writeln('## Light Theme Results');
  buffer.writeln();
  buffer.writeln(
    '| Context | Foreground | Background | Ratio | Required | Status |',
  );
  buffer.writeln(
    '|---------|------------|------------|-------|----------|--------|',
  );

  for (final r in results.where((r) => r.context.startsWith('Light:'))) {
    buffer.writeln(
      '| ${r.context.replaceFirst('Light: ', '')} | ${r.foreground.hex} | ${r.background.hex} | ${r.ratioStr} | ${r.requiredRatio}:1 | ${r.status} |',
    );
  }

  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();

  // Dark Theme Results
  buffer.writeln('## Dark Theme Results');
  buffer.writeln();
  buffer.writeln(
    '| Context | Foreground | Background | Ratio | Required | Status |',
  );
  buffer.writeln(
    '|---------|------------|------------|-------|----------|--------|',
  );

  for (final r in results.where((r) => r.context.startsWith('Dark:'))) {
    buffer.writeln(
      '| ${r.context.replaceFirst('Dark: ', '')} | ${r.foreground.hex} | ${r.background.hex} | ${r.ratioStr} | ${r.requiredRatio}:1 | ${r.status} |',
    );
  }

  buffer.writeln();

  // Failed checks
  final failedResults = results.where((r) => !r.passes).toList();
  if (failedResults.isNotEmpty) {
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('## ❌ Failed Checks - Recommendations');
    buffer.writeln();
    for (final r in failedResults) {
      final deficit = r.requiredRatio - r.ratio;
      buffer.writeln('### ${r.context}');
      buffer.writeln();
      buffer.writeln('- **Foreground:** ${r.foreground}');
      buffer.writeln('- **Background:** ${r.background}');
      buffer.writeln('- **Current ratio:** ${r.ratioStr}');
      buffer.writeln('- **Required ratio:** ${r.requiredRatio}:1');
      buffer.writeln('- **Deficit:** ${deficit.toStringAsFixed(2)}');
      buffer.writeln();
      buffer.writeln(
        '**Recommendation:** Adjust the foreground color to be ${r.foreground.r > 128 ? "darker" : "lighter"} to achieve the required contrast ratio.',
      );
      buffer.writeln();
    }
  } else {
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('## ✅ All Checks Passed');
    buffer.writeln();
    buffer.writeln(
      'All color combinations meet WCAG 2.1 AA minimum contrast requirements.',
    );
  }

  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();
  buffer.writeln('## Technical Notes');
  buffer.writeln();
  buffer.writeln('### Relative Luminance Formula (sRGB)');
  buffer.writeln();
  buffer.writeln('```');
  buffer.writeln('L = 0.2126 * R + 0.7152 * G + 0.0722 * B');
  buffer.writeln('```');
  buffer.writeln();
  buffer.writeln('Where R, G, B are linearized values:');
  buffer.writeln('```');
  buffer.writeln('if sRGB <= 0.03928:');
  buffer.writeln('    linear = sRGB / 12.92');
  buffer.writeln('else:');
  buffer.writeln('    linear = ((sRGB + 0.055) / 1.055) ^ 2.4');
  buffer.writeln('```');
  buffer.writeln();
  buffer.writeln('### Contrast Ratio Formula');
  buffer.writeln();
  buffer.writeln('```');
  buffer.writeln('ratio = (L1 + 0.05) / (L2 + 0.05)');
  buffer.writeln('```');
  buffer.writeln();
  buffer.writeln(
    'Where L1 is the luminance of the lighter color and L2 is the luminance of the darker color.',
  );

  return buffer.toString();
}

void main() {
  print('🎨 WCAG 2.1 Contrast Checker for PH Fare Calculator');
  print('=' * 60);
  print('');

  final results = runAllChecks();

  // Print console summary
  final passed = results.where((r) => r.passes).length;
  final failed = results.where((r) => !r.passes).length;

  print('Summary:');
  print('  Total checks: ${results.length}');
  print('  ✅ Passed: $passed');
  print('  ❌ Failed: $failed');
  print('');

  // Print failed checks to console
  if (failed > 0) {
    print('Failed Checks:');
    for (final r in results.where((r) => !r.passes)) {
      print('  ❌ ${r.context}');
      print('     ${r.foreground} on ${r.background}');
      print('     Ratio: ${r.ratioStr} (required: ${r.requiredRatio}:1)');
      print('');
    }
  }

  // Generate and write markdown report
  final report = generateMarkdownReport(results);
  final reportFile = File('docs/accessibility_audit.md');
  reportFile.writeAsStringSync(report);

  print('📄 Report written to: docs/accessibility_audit.md');
  print('');

  // Exit with appropriate code
  if (failed > 0) {
    print('⚠️  Some contrast checks failed. Review the report for details.');
    exit(1);
  } else {
    print('✅ All contrast checks passed!');
    exit(0);
  }
}
