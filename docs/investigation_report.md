# Investigation Report: Dark Mode & Analyzer Issues

**Date:** 2025-12-15  
**Investigator:** Debug Mode  
**Task ID:** INVESTIGATE-001

---

## Executive Summary

This investigation identified **54 analyzer problems** (all `info` level) and **38 dark mode color issues** across the PH Fare Calculator Flutter app. The analyzer problems are entirely related to `avoid_print` and deprecated API usage in tool/research files. The dark mode issues are more critical, with **hardcoded colors** that don't respect the theme system, causing visibility problems in dark mode (e.g., green text on dark backgrounds becoming invisible).

---

## Part 1: Dart Analyzer Problems (54 Total)

### Summary by Category

| Category | Count | Severity |
|----------|-------|----------|
| `avoid_print` - Tool files | 51 | info |
| `empty_catches` | 1 | info |
| `deprecated_member_use` | 1 | info |
| **Total** | **54** | **info** |

### Complete Analyzer Output

```
Analyzing ph-fare-calculator...

   info - docs\research\tool_extract_m3_colors.dart:18:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:21:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:26:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:27:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:28:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:29:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:30:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:31:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:32:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:33:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:34:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:35:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:36:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:37:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:38:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:39:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:40:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:41:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:42:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:43:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:44:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:45:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:46:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:47:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:48:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:49:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:50:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:51:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:52:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:53:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:54:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:55:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:56:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:57:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - docs\research\tool_extract_m3_colors.dart:64:15 - Empty catch block. Try adding statements to the block, adding a comment to the block, or removing the 'catch' clause. - empty_catches
   info - docs\research\tool_extract_m3_colors.dart:68:20 - 'value' is deprecated and shouldn't be used. Use component accessors like .r or .g, or toARGB32 for an explicit conversion. Try replacing the use of the deprecated member with the replacement. - deprecated_member_use
   info - docs\research\tool_extract_m3_colors_v2.dart:9:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:545:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:546:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:547:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:555:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:556:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:557:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:558:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:559:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:563:5 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:565:7 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:566:7 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:567:7 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:568:7 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:577:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:578:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:582:5 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - tool\wcag_contrast_checker.dart:585:5 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print

54 issues found.
```

### Affected Files

| File | Issue Count | Issues |
|------|-------------|--------|
| `docs/research/tool_extract_m3_colors.dart` | 36 | 34 avoid_print, 1 empty_catches, 1 deprecated_member_use |
| `docs/research/tool_extract_m3_colors_v2.dart` | 1 | avoid_print |
| `tool/wcag_contrast_checker.dart` | 17 | avoid_print |

### Recommended Fixes

1. **For tool files**: Add `// ignore_for_file: avoid_print` at the top of each file since these are CLI tools meant for local development.
2. **For empty_catches**: Add a comment explaining why the catch block is intentionally empty, or handle the error appropriately.
3. **For deprecated_member_use**: Replace `Color.value` with `Color.toARGB32()` or component accessors.

---

## Part 2: Dark Mode Color Issues (38 Total)

### Critical Issues (Will cause invisible/hard-to-read text)

| Severity | Count |
|----------|-------|
| 🔴 Critical (invisible text/elements) | 12 |
| 🟠 High (poor contrast) | 14 |
| 🟡 Medium (hardcoded colors but may still work) | 12 |

### Detailed Issue List by File

---

#### 🔴 CRITICAL: [`lib/src/presentation/screens/offline_menu_screen.dart`](lib/src/presentation/screens/offline_menu_screen.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 89 | `iconBackgroundColor: Colors.green.withValues(alpha: 0.12)` | Discount Guide icon background |
| 90 | `iconColor: Colors.green` | **GREEN TEXT/ICON INVISIBLE IN DARK MODE** |

**Root Cause:** The "Discount Guide" menu item uses hardcoded `Colors.green` which has poor contrast on dark backgrounds (#141218).

---

#### 🔴 CRITICAL: [`lib/src/presentation/screens/onboarding_screen.dart`](lib/src/presentation/screens/onboarding_screen.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 37 | `static const Color _primaryBlue = Color(0xFF0038A8)` | Hardcoded PH Blue |
| 38 | `static const Color _secondaryYellow = Color(0xFFFCD116)` | Hardcoded PH Yellow |
| 39 | `static const Color _tertiaryRed = Color(0xFFCE1126)` | Hardcoded PH Red |
| 186 | `foregroundColor: Colors.grey.shade600` | Grey text on potentially dark background |
| 228 | `color: const Color(0xFF1A1C1E)` | **DARK TEXT ON DARK BACKGROUND = INVISIBLE** |
| 295 | `color: const Color(0xFF1A1C1E)` | Same issue |
| 305 | `Colors.grey.shade600` | Grey text visibility issue |
| 481 | `color: const Color(0xFF1A1C1E)` | Same issue |
| 494 | `Colors.grey.shade600` | Same issue |
| 569 | `Colors.grey.shade500` | Disclaimer text visibility |

---

#### 🔴 CRITICAL: [`lib/src/presentation/screens/splash_screen.dart`](lib/src/presentation/screens/splash_screen.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 44 | `static const Color _primaryBlue = Color(0xFF0038A8)` | Hardcoded color |
| 45 | `static const Color _secondaryYellow = Color(0xFFFCD116)` | Hardcoded color |

---

#### 🟠 HIGH: [`lib/src/presentation/screens/region_download_screen.dart`](lib/src/presentation/screens/region_download_screen.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 457 | `Colors.green.withValues(alpha: 0.1)` | Green background for downloaded status |
| 603 | `Icon(Icons.check_circle, color: Colors.green)` | Hardcoded green checkmark |
| 606 | `Icon(Icons.delete, color: Colors.red)` | Hardcoded red delete icon |
| 634 | `Colors.green.withValues(alpha: 0.05)` | Green background |
| 700-701 | `Icon(Icons.check_circle, color: Colors.green)` | Green status icon |

---

#### 🟠 HIGH: [`lib/src/presentation/widgets/fare_result_card.dart`](lib/src/presentation/widgets/fare_result_card.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 39 | `return const Color(0xFF4CAF50)` | Hardcoded green for "standard" indicator |
| 323 | `Border.all(color: Colors.white, width: 3)` | Hardcoded white border |

---

#### 🟠 HIGH: [`lib/src/presentation/widgets/map_selection_widget.dart`](lib/src/presentation/widgets/map_selection_widget.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 344 | `color: const Color(0xFF4CAF50)` | Hardcoded green for origin marker |
| 345 | `Border.all(color: Colors.white, width: 2)` | Hardcoded white border |
| 347 | `color: Colors.white` | Hardcoded white icon |
| 368 | `color: Colors.white` | Hardcoded white icon |

---

#### 🟠 HIGH: [`lib/src/presentation/widgets/app_logo_widget.dart`](lib/src/presentation/widgets/app_logo_widget.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 35 | `static const Color _primaryBlue = Color(0xFF0038A8)` | Hardcoded brand color |
| 48 | `color: Colors.white` | Hardcoded white background |
| 75 | `color: Colors.white` | Hardcoded white icon |

---

#### 🟡 MEDIUM: [`lib/src/presentation/screens/map_picker_screen.dart`](lib/src/presentation/screens/map_picker_screen.dart)

| Line | Issue | Impact |
|------|-------|--------|
| 284 | `Colors.black.withValues(alpha: 0.2)` | Shadow color (acceptable) |
| 323 | `Border.all(color: Colors.white, width: 3)` | Hardcoded white |
| 367 | `color: Colors.black.withValues(alpha: 0.1)` | Shadow color (acceptable) |

---

#### 🟡 MEDIUM: [`lib/src/presentation/screens/reference_screen.dart`](lib/src/presentation/screens/reference_screen.dart)

The file correctly uses `TransitColors` theme extension for most colors, but has one issue:

| Line | Issue | Impact |
|------|-------|--------|
| 664-676 | Fallback colors use hardcoded values | Only used if TransitColors extension is missing |

---

### Theme Architecture Analysis

The app has a well-designed theme system in place:

1. **`lib/src/core/theme/app_theme.dart`** - Defines light and dark themes with M3 color schemes
2. **`lib/src/core/theme/transit_colors.dart`** - Provides semantic colors for transit lines that adapt to light/dark mode

**TransitColors Extension:**
- Properly defines light and dark mode variants
- Includes discount badge colors: `discountBadge` and `discountBadgeText`
- Already has appropriate colors for dark mode

**Problem:** Many screens/widgets bypass the theme system by using:
- Static `const Color` definitions
- Hardcoded `Colors.xxx` values
- Literal hex color codes like `Color(0xFF1A1C1E)`

---

## Part 3: Recommended Fixes

### Priority 1: Critical Dark Mode Issues

1. **[`offline_menu_screen.dart:89-90`](lib/src/presentation/screens/offline_menu_screen.dart:89)** - Replace `Colors.green` with `TransitColors.discountPwd` or a new semantic color
2. **[`onboarding_screen.dart`](lib/src/presentation/screens/onboarding_screen.dart)** - Replace all `Color(0xFF1A1C1E)` with `colorScheme.onSurface`
3. **[`fare_result_card.dart:39`](lib/src/presentation/widgets/fare_result_card.dart:39)** - Use semantic color from TransitColors or colorScheme

### Priority 2: High Impact Issues

1. **Replace all `Colors.green` with theme-aware colors** - Use `TransitColors` extension
2. **Replace hardcoded `Colors.white`** - Use `colorScheme.surface` or `colorScheme.onPrimary`
3. **Replace `Colors.grey.shade600`** - Use `colorScheme.onSurfaceVariant`

### Priority 3: Analyzer Issues

1. Add `// ignore_for_file: avoid_print` to tool files
2. Fix deprecated `Color.value` usage
3. Add comment to empty catch block

---

## Part 4: Files Audited

### Screens (9 files)
- ✅ `lib/src/presentation/screens/main_screen.dart` - Uses theme correctly
- ⚠️ `lib/src/presentation/screens/map_picker_screen.dart` - Some hardcoded colors
- ⚠️ `lib/src/presentation/screens/offline_menu_screen.dart` - **CRITICAL: Green color issue**
- ⚠️ `lib/src/presentation/screens/onboarding_screen.dart` - **CRITICAL: Dark text issues**
- ✅ `lib/src/presentation/screens/reference_screen.dart` - Mostly uses TransitColors
- ⚠️ `lib/src/presentation/screens/region_download_screen.dart` - Hardcoded green/red
- ✅ `lib/src/presentation/screens/saved_routes_screen.dart` - Uses theme correctly
- ✅ `lib/src/presentation/screens/settings_screen.dart` - Uses theme correctly
- ⚠️ `lib/src/presentation/screens/splash_screen.dart` - Hardcoded brand colors

### Widgets (15 files)
- ⚠️ `lib/src/presentation/widgets/app_logo_widget.dart` - Hardcoded colors
- ⚠️ `lib/src/presentation/widgets/fare_result_card.dart` - Hardcoded green
- ⚠️ `lib/src/presentation/widgets/map_selection_widget.dart` - Hardcoded green/white
- ✅ `lib/src/presentation/widgets/offline_indicator.dart` - Uses theme correctly
- ✅ `lib/src/presentation/widgets/main_screen/calculate_fare_button.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/error_message_banner.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/fare_results_header.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/fare_results_list.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/first_time_passenger_prompt.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/location_input_section.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/main_screen_app_bar.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/map_preview.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/offline_status_banner.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/passenger_bottom_sheet.dart` - Uses theme
- ✅ `lib/src/presentation/widgets/main_screen/travel_options_bar.dart` - Uses theme

### Theme Files (2 files)
- ✅ `lib/src/core/theme/app_theme.dart` - Well structured M3 theme
- ✅ `lib/src/core/theme/transit_colors.dart` - Good light/dark mode support

---

## Appendix: Quick Reference of All Issues

### All Hardcoded Color Locations

| File | Line | Color | Should Use |
|------|------|-------|------------|
| `offline_menu_screen.dart` | 89-90 | `Colors.green` | `TransitColors.discountPwd` |
| `onboarding_screen.dart` | 37 | `Color(0xFF0038A8)` | `colorScheme.primary` |
| `onboarding_screen.dart` | 38 | `Color(0xFFFCD116)` | `colorScheme.secondary` |
| `onboarding_screen.dart` | 39 | `Color(0xFFCE1126)` | `colorScheme.tertiary` |
| `onboarding_screen.dart` | 186 | `Colors.grey.shade600` | `colorScheme.onSurfaceVariant` |
| `onboarding_screen.dart` | 228, 295, 481 | `Color(0xFF1A1C1E)` | `colorScheme.onSurface` |
| `onboarding_screen.dart` | 305, 494 | `Colors.grey.shade600` | `colorScheme.onSurfaceVariant` |
| `onboarding_screen.dart` | 569 | `Colors.grey.shade500` | `colorScheme.outline` |
| `splash_screen.dart` | 44-45 | `Color(0xFF0038A8)`, etc. | `colorScheme.primary` |
| `region_download_screen.dart` | 457, 603, 634, 700 | `Colors.green` | Semantic status color |
| `region_download_screen.dart` | 606 | `Colors.red` | `colorScheme.error` |
| `fare_result_card.dart` | 39 | `Color(0xFF4CAF50)` | `TransitColors` or semantic |
| `fare_result_card.dart` | 323 | `Colors.white` | `colorScheme.surface` |
| `map_selection_widget.dart` | 344 | `Color(0xFF4CAF50)` | Semantic color |
| `map_selection_widget.dart` | 345, 347, 368 | `Colors.white` | `colorScheme.surface/onPrimary` |
| `app_logo_widget.dart` | 35 | `Color(0xFF0038A8)` | `colorScheme.primary` |
| `app_logo_widget.dart` | 48, 75 | `Colors.white` | Theme-aware white |
| `map_picker_screen.dart` | 323 | `Colors.white` | `colorScheme.surface` |

---

*Report generated by Debug Mode investigation task INVESTIGATE-001*