# Module 01: Localization (l10n) Issues

## Purpose
This module documents hardcoded strings, missing localization keys, and internationalization anti-patterns found in the Pasahe app. It serves as a reference for developers implementing full i18n coverage (English + Tagalog).

## Findings Table

| ID | Severity | Location | Issue | WCAG Impact | Effort | Status |
|----|----------|----------|-------|-------------|--------|--------|
| L10n-01 | **High** | `presentation/screens/main_screen.dart:298` | Hardcoded error string: `'Failed to get location'` | Screen reader may read untranslated text | 5 min | 🔴 Open |
| L10n-02 | **High** | `presentation/screens/main_screen.dart:346` | Hardcoded error string: `'Failed to get address'` | Screen reader may read untranslated text | 5 min | 🔴 Open |
| L10n-03 | **High** | `presentation/screens/map_picker_screen.dart:320` | Hardcoded map picker label strings | Tagalog users see English labels | 10 min | 🔴 Open |
| L10n-04 | **High** | `presentation/screens/onboarding_screen.dart` | Multiple hardcoded onboarding strings (lines 181, 190, 404, 413, 560, 575) | First-run UX not localized | 30 min | 🔴 Open |
| L10n-05 | **High** | `presentation/screens/reference_screen.dart:123` | Hardcoded title: `'Fare Reference Guide'` | Core feature label untranslated | 5 min | 🔴 Open |
| L10n-06 | **High** | `presentation/screens/reference_screen.dart:305` | Hardcoded button label: `'Retry'` | Action button not localized | 5 min | 🔴 Open |
| L10n-07 | **Medium** | `presentation/screens/settings_screen.dart:1345-1381` | Hardcoded cache management strings (`'Map Cache Size'`, `'Clear'`, etc.) | Settings UX partially untranslated | 15 min | 🔴 Open |
| L10n-08 | **Medium** | `presentation/widgets/main_screen/passenger_bottom_sheet.dart:139,152` | Hardcoded dialog strings: `'Cancel'`, `'Apply'` | Bottom sheet actions not localized | 10 min | 🔴 Open |
| L10n-09 | **Medium** | `presentation/widgets/main_screen/transport_mode_selection_modal.dart:266` | Hardcoded modal string: `'Cancel'` | Modal actions not localized | 5 min | 🔴 Open |
| L10n-10 | **Medium** | `presentation/screens/region_download_screen.dart` | 8+ hardcoded strings for download/delete operations | File management UX untranslated | 20 min | 🔴 Open |
| L10n-11 | **Medium** | `presentation/screens/saved_routes_screen.dart:78,128` | Hardcoded dialog strings: `'Delete Route'`, `'Delete'` | Route management not localized | 10 min | 🔴 Open |
| L10n-12 | **Low** | `presentation/widgets/main_screen/travel_options_bar.dart:175,189,203` | Hardcoded sort labels: `'Lowest Price'`, `'Highest Price'`, `'Lowest Overall'` | Sort options not localized | 10 min | 🔴 Open |

**Total Findings:** 12 distinct issues across 8 files  
**Critical Path:** L10n-01 through L10n-06 (user-facing error messages and onboarding)

## Evidence (Code Snippets)

### Finding L10n-01: Hardcoded Error Message
**File:** `lib/src/presentation/screens/main_screen.dart`  
**Line:** 298

```dart
// ❌ Hardcoded - not in app_en.arb
content: Text(_controller.errorMessage ?? 'Failed to get location'),
```

**Evidence Context:**
```dart
// Line 295-300
SnackBar(
  content: Text(_controller.errorMessage ?? 'Failed to get location'),
  behavior: SnackBarBehavior.floating,
);
```

**Required Fix:**
```dart
// ✅ Localized with fallback
content: Text(_controller.errorMessage ?? AppLocalizations.of(context)!.locationErrorFallback),
```

---

### Finding L10n-02: Duplicate Pattern
**File:** `lib/src/presentation/screens/main_screen.dart`  
**Line:** 346

```dart
content: Text(_controller.errorMessage ?? 'Failed to get address'),
```

**Pattern:** Same anti-pattern as L10n-01, different error context.

---

### Finding L10n-03: Map Picker Hardcoded Strings
**File:** `lib/src/presentation/screens/map_picker_screen.dart`  
**Lines:** 320-360 range

```dart
// Line 320 - hardcoded in widget tree
child: Text(
  'Pin location',
  style: TextStyle(fontSize: 14),  // Also hardcoded font size (see Typography-04)
),

// Line 359 - hardcoded
child: Text('Confirm Location'),
```

**Edge Case:** These strings appear in map overlay UI where screen real estate is limited - localized strings may be longer and require truncation handling.

---

### Finding L10n-04: Onboarding Screen (High Density)
**File:** `lib/src/presentation/screens/onboarding_screen.dart`  
**Lines:** Multiple

```dart
// Line 181
child: TextButton(
  child: const Text('Skip'),  // ❌ Hardcoded
),

// Line 190
child: Text(
  'Welcome to Pasahe',  // ❌ Hardcoded
  style: const TextStyle(fontSize: 24),  // Also Typography-05
),

// Line 404
child: Text(
  'Calculate fares easily',  // ❌ Hardcoded
  style: const TextStyle(fontSize: 16),
),

// Line 560
child: Text(
  'Get Started',  // ❌ Hardcoded
  style: const TextStyle(fontSize: 16),
),
```

**Impact:** Onboarding is the first user experience - complete localization here is critical for Tagalog-speaking users.

---

### Finding L10n-05 & L10n-06: Reference Screen
**File:** `lib/src/presentation/screens/reference_screen.dart`

```dart
// Line 123
AppBar(
  title: const Text('Fare Reference Guide'),  // L10n-05
),

// Line 305
ElevatedButton(
  child: const Text('Retry'),  // L10n-06
),
```

**Edge Case:** `'Fare Reference Guide'` is a compound noun that may not translate directly to Tagalog - may require semantic equivalent.

---

### Finding L10n-07: Settings Screen Cache Management
**File:** `lib/src/presentation/screens/settings_screen.dart`  
**Lines:** 1345-1381

```dart
// Line 1345
title: const Text('Map Cache Size'),  // ❌ Hardcoded

// Line 1349
child: const Text('Clear'),  // ❌ Hardcoded

// Line 1359
title: const Text('Clear Map Cache?'),  // ❌ Hardcoded

// Line 1366
child: const Text('Cancel'),  // ❌ Hardcoded

// Line 1370
child: const Text('Clear'),  // ❌ Hardcoded

// Line 1381
const SnackBar(content: Text('Map cache cleared')),  // ❌ Hardcoded
```

**Pattern:** Batch of 6 hardcoded strings in cache management flow - candidate for single PR.

---

### Finding L10n-08: Passenger Bottom Sheet
**File:** `lib/src/presentation/widgets/main_screen/passenger_bottom_sheet.dart`  
**Lines:** 139, 152

```dart
// Line 139
child: const Text('Cancel'),

// Line 152
child: const Text('Apply'),
```

**Note:** `'Apply'` as a verb may have different translations depending on context (apply changes vs apply for something).

---

### Finding L10n-09: Transport Mode Selection Modal
**File:** `lib/src/presentation/widgets/main_screen/transport_mode_selection_modal.dart`  
**Line:** 266

```dart
child: const Text('Cancel'),
```

**Pattern:** Same string as L10n-08 - requires consistent translation.

---

### Finding L10n-10: Region Download Screen (Batch)
**File:** `lib/src/presentation/screens/region_download_screen.dart`  
**Lines:** Multiple (95, 106, 128, 140, 147, 154, 167, 179, 186, 193...)

```dart
// Line 95 - success message
content: Text('${progress.region.name} downloaded successfully!'),

// Line 106 - error message
content: Text('Download failed: ${progress.errorMessage}'),

// Line 140 - dialog title
title: Text('Delete ${region.name}?'),

// Line 147 - button
child: const Text('Cancel'),

// Line 154 - button
child: const Text('Delete'),
```

**Edge Case:** Interpolated strings (`${region.name}`) require parameterized localization keys.

---

### Finding L10n-11: Saved Routes Screen
**File:** `lib/src/presentation/screens/saved_routes_screen.dart`  
**Lines:** 78, 128

```dart
// Line 78 - dialog title
const Text('Delete Route'),

// Line 128 - button
child: const Text('Delete'),
```

---

### Finding L10n-12: Travel Options Bar
**File:** `lib/src/presentation/widgets/main_screen/travel_options_bar.dart`  
**Lines:** 175, 189, 203

```dart
// Line 175
const Text('Lowest Price'),

// Line 189
const Text('Highest Price'),

// Line 203
const Text('Lowest Overall'),
```

**Context:** These are sort/filter labels that should match the localized transport mode names.

## Edge Cases

### Edge Case L10n-E1: String Interpolation with Named Parameters
**Location:** `region_download_screen.dart`  
**Challenge:** Strings like `'${region.name} downloaded successfully!'` mix hardcoded text with dynamic data.

**Required l10n Pattern:**
```json
{
  "regionDownloadSuccess": "{regionName} downloaded successfully!",
  "@regionDownloadSuccess": {
    "placeholders": {
      "regionName": {"type": "String"}
    }
  }
}
```

### Edge Case L10n-E2: Context-Dependent Translations
**Location:** Multiple files  
**Challenge:** Single word `'Cancel'` appears in multiple contexts (dialog dismissal, form reset, download abort) - may need different Tagalog translations.

**Required Pattern:** Context-specific keys:
- `cancelAction` (general)
- `cancelDownload` (specific to downloads)
- `cancelDialog` (dialog dismissal)

### Edge Case L10n-E3: Concatenated Strings
**Location:** `fare_result_card.dart`  
**Challenge:** Semantic label building via StringBuffer may concatenate translated fragments incorrectly.

**Evidence:**
```dart
// Lines 253-270 in fare_result_card.dart
String _buildSemanticLabel() {
  final buffer = StringBuffer();
  buffer.write('Fare estimate for $transportMode is ');  // Hardcoded
  buffer.write('${totalFare.toStringAsFixed(2)} pesos');  // Hardcoded "pesos"
  // ...
}
```

**Risk:** "pesos" is hardcoded currency name - should use localized currency symbol.

### Edge Case L10n-E4: Error Message Fallback Chain
**Location:** `main_screen.dart:298`  
**Challenge:** `_controller.errorMessage` may already be localized OR may be a raw exception string.

**Current:**
```dart
Text(_controller.errorMessage ?? 'Failed to get location')
```

**Risk:** If `errorMessage` contains a system exception (e.g., `'TimeoutException after 0:00:05.000000: Future not completed'`), user sees untranslated technical error.

## Recommendations

### Immediate Actions (This Sprint)
1. **Create localization keys for error messages** (L10n-01, L10n-02) - Critical for accessibility
2. **Localize onboarding flow** (L10n-04) - First impression for Tagalog users
3. **Add context-specific Cancel keys** (L10n-E2) - Ensure semantic accuracy

### Short Term (Next 2 Sprints)
4. Batch-convert settings screen strings (L10n-07)
5. Localize region download operations (L10n-10) - Requires parameter handling
6. Audit all SnackBar content (L10n-07, others) - Often missed in l10n passes

### Long Term (Technical Debt)
7. Implement lint rule: `avoid_hardcoded_strings` (custom) or use `prefer_const_literals`, `prefer_final_locals` as partial mitigation
8. Add CI check: Fail build if new hardcoded strings detected (compare against l10n arb files)

### Migration Script
```bash
# Find all suspicious Text widgets with string literals
flutter pub run build_runner build  # Generate l10n first
grep -rn "const Text('" lib/src/presentation --include="*.dart" | grep -v "Text(AppLocalizations"
```

---

**Related Modules:**
- Module 02: Typography Issues (hardcoded TextStyle with strings)
- Module 04: Accessibility Strengths (Semantics usage patterns)
- Module 10: Prioritized Fix Backlog (ranking)
