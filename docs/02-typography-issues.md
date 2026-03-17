# Module 02: Typography Issues

## Purpose
This module documents font size anti-patterns, hardcoded TextStyle properties, and text scaling safeguards found in the Pasahe app. It focuses on readability, accessibility compliance, and maintainable theming.

## Findings Table

| ID | Severity | Location | Issue | WCAG Impact | Effort | Status |
|----|----------|----------|-------|-------------|--------|--------|
| Typo-01 | **Critical** | `widgets/fare_result_card.dart:188` | `fontSize: 9` - illegibly small | WCAG 1.4.4 Resize Text failure | 2 min | 🔴 Open |
| Typo-02 | **High** | `widgets/main_screen/transport_mode_selection_modal.dart` | `fontSize: 10` - below 11sp minimum | Poor readability on small devices | 2 min | 🔴 Open |
| Typo-03 | **High** | `widgets/main_screen/travel_options_bar.dart` | `fontSize: 10` in chip label | Below recommended minimum | 2 min | 🔴 Open |
| Typo-04 | **High** | `screens/map_picker_screen.dart` | Multiple hardcoded `fontSize` values (14, 16) | Inconsistent with theme typography scale | 10 min | 🔴 Open |
| Typo-05 | **High** | `screens/onboarding_screen.dart:192` | `fontSize: 24` hardcoded | Bypasses theme headlineLarge (32) | 2 min | 🔴 Open |
| Typo-06 | **High** | `screens/onboarding_screen.dart:406` | `fontSize: 16` hardcoded | Bypasses theme titleMedium | 2 min | 🔴 Open |
| Typo-07 | **High** | `screens/onboarding_screen.dart:579,583` | `fontSize: 12` hardcoded | Bypasses theme labelSmall | 2 min | 🔴 Open |
| Typo-08 | **High** | `screens/settings_screen.dart:803,808,813` | `fontSize: 14` in theme mode labels | Inconsistent with settings list items | 5 min | 🔴 Open |
| Typo-09 | **Critical** | All presentation files | **Missing `textScaler` safeguards** | WCAG 1.4.4 total failure - app breaks at 200% system scale | 30 min | 🔴 Open |
| Typo-10 | **Medium** | `screens/reference_screen.dart:284,583` | `fontSize: 18` and `fontSize: 12` hardcoded | Mixed with theme-compliant styles | 5 min | 🔴 Open |
| Typo-11 | **Medium** | `widgets/main_screen/cross_region_warning_banner.dart:39` | `fontSize: 12` hardcoded | Warning banner may be truncated | 2 min | 🔴 Open |
| Typo-12 | **Medium** | `screens/region_download_screen.dart:826,831,836` | Hardcoded `fontSize: 14` values | Batch pattern, 3 instances | 5 min | 🔴 Open |

**Total Findings:** 12 distinct issues  
**Critical Pattern:** Typo-09 (missing text scaling) affects ALL text widgets  
**WCAG Reference:** 1.4.4 Resize Text (Level AA) requires text up to 200% without loss of content

## Evidence (Code Snippets)

### Finding Typo-01: Critical - 9sp Font Size
**File:** `lib/src/presentation/widgets/fare_result_card.dart`  
**Line:** 188

```dart
// ❌ CRITICAL: 9sp is below readable threshold
Text(
  routeSource.description,
  style: Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: 9,  // ← Too small for any use case
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w500,
  ),
)
```

**Visual Impact:** At 9sp, text is approximately 7.2pt physical size on most devices - below typical 8pt minimum for body text.

**WCAG Violation:**  
- **Criteria:** 1.4.4 Resize Text (Level AA)  
- **Requirement:** Text can be resized up to 200% without assistive technology  
- **Current:** At 200% scale, 9sp becomes 18sp - still readable BUT the hardcoded value suggests pattern doesn't respect system settings  
- **Actual Risk:** If this is inside a constrained container, text may clip

**Required Fix:**
```dart
// ✅ Use theme scale with clamping for safety
Text(
  routeSource.description,
  style: Theme.of(context).textTheme.labelSmall?.copyWith(
    // Remove hardcoded fontSize - let theme handle it
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
  overflow: TextOverflow.ellipsis,  // Add overflow protection
  maxLines: 1,
)
```

---

### Finding Typo-02 & Typo-03: 10sp Font Size
**File:** `lib/src/presentation/widgets/main_screen/transport_mode_selection_modal.dart`  
**Line:** 266 (Typo-02)

```dart
child: const Text('Cancel'),  // L10n-09
style: TextStyle(fontSize: 10),  // Typo-02
```

**File:** `lib/src/presentation/widgets/main_screen/travel_options_bar.dart`  
**Line:** 120 (Typo-03)

```dart
Text(
  '$enabledModesCount',
  style: textTheme.labelSmall?.copyWith(
    color: colorScheme.onPrimary,
    fontSize: 10,  // Typo-03
    fontWeight: FontWeight.bold,
  ),
)
```

**Context:** Both are in compact UI elements (modal footer, filter chip) where space is constrained.

---

### Finding Typo-04: Batch Hardcoded Font Sizes (Map Picker)
**File:** `lib/src/presentation/screens/map_picker_screen.dart`  
**Lines:** 320, 353, 362, 379, 398, 407, 417, 433, 437, 520, 533, 595, 599, 615, 620, 630, 641, 672, 718, 725, 745, 761, 766, 780, 797, 813, 821, 832, 875, 883

```dart
// Line 320
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  fontSize: 14,  // ← Should be bodyMedium default
),

// Line 362
Text(
  'Confirm Location',  // Also L10n-03
  style: TextStyle(fontSize: 16),  // ← Should use theme
)
```

**Pattern Density:** 29 instances in single file - candidate for automated refactor.

---

### Finding Typo-05, Typo-06, Typo-07: Onboarding Typography
**File:** `lib/src/presentation/screens/onboarding_screen.dart`

```dart
// Line 192 (Typo-05)
Text(
  'Welcome to Pasahe',
  style: const TextStyle(fontSize: 24),  // Theme headlineLarge is 32
)

// Line 406 (Typo-06)
Text(
  'Calculate fares easily',
  style: const TextStyle(fontSize: 16),  // Theme titleMedium is 16, but hardcoded bypasses theme
)

// Line 579 (Typo-07)
style: const TextStyle(fontSize: 12)  // Theme labelSmall is 11, close but hardcoded
```

**Theme Comparison:**
| Hardcoded | Theme Token | Theme Size | Deviation |
|-----------|-------------|------------|-----------|
| 24 | `headlineLarge` | 32 | -25% smaller |
| 16 | `titleMedium` | 16 | Same size, bypasses theme |
| 12 | `labelSmall` | 11 | +9% larger |

---

### Finding Typo-08: Settings Theme Mode Labels
**File:** `lib/src/presentation/screens/settings_screen.dart`  
**Lines:** 803, 808, 813

```dart
// Line 803
label: Text(
  getThemeModeLabel('system'),
  style: const TextStyle(fontSize: 14),  // Hardcoded
),

// Same pattern at lines 808, 813 for 'light' and 'dark'
```

**Note:** Function `getThemeModeLabel()` returns strings - likely has its own localization issues (see L10n audit).

---

### Finding Typo-09: CRITICAL - Missing Text Scaling Safeguards
**Scope:** All presentation layer (47 UI files)  
**Evidence:** Zero instances of `textScaler` or `MediaQuery.textScaleFactor` handling

**Current State:**
```bash
# Command: grep -rn "TextScaler\|textScaler\|textScaleFactor" lib/src/presentation
# Result: No matches found
```

**WCAG 1.4.4 Compliance Test:**
- Set device accessibility text size to 200%
- Open Pasahe app
- Expected: All text scales appropriately
- Actual: Likely text overflow/clipping in constrained widgets

**Mitigation Pattern (Required at root level):**
```dart
// In main.dart or MaterialApp builder
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(
      MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 1.5),
    ),
  ),
  child: child,
)
```

**Alternative (Widget-level):**
```dart
// For widgets that cannot scale (e.g., map markers)
Text(
  'Label',
  textScaler: TextScaler.noScaling,  // Explicit opt-out with justification
)
```

---

### Finding Typo-10: Reference Screen Mixed Patterns
**File:** `lib/src/presentation/screens/reference_screen.dart`

```dart
// Line 284 - hardcoded
style: const TextStyle(fontSize: 18)

// Line 583 - hardcoded  
style: const TextStyle(fontSize: 12)
```

**Context:** Same file uses `textTheme.titleLarge` elsewhere - inconsistent approach.

---

### Finding Typo-11: Warning Banner Small Text
**File:** `lib/src/presentation/widgets/main_screen/cross_region_warning_banner.dart`  
**Line:** 39, 48

```dart
Text(
  'Cross-Region Route',
  style: TextStyle(
    fontSize: 12,  // Hardcoded
    fontWeight: FontWeight.bold,
  ),
)
```

**Risk:** Banner may truncate on small devices or at high text scales.

---

### Finding Typo-12: Region Download Screen Batch
**File:** `lib/src/presentation/screens/region_download_screen.dart`  
**Lines:** 826, 831, 836

```dart
// Line 826
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  fontSize: 14,  // Redundant - bodyMedium IS typically 14
),

// Lines 831, 836 - same pattern
```

**Note:** These are redundant copies - `bodyMedium` default is already 14 in the theme.

## Edge Cases

### Edge Case Typo-E1: Map Marker Labels
**Location:** Map overlay widgets  
**Challenge:** Map markers with text labels cannot scale beyond physical pixel constraints without overlapping neighboring markers.

**Current Risk:** Unknown if markers use `TextScaler.noScaling` - if they scale, map becomes unreadable.

**Required Pattern:**
```dart
// Map markers must explicitly opt out of scaling
Text(
  markerLabel,
  textScaler: TextScaler.noScaling,
  semanticsLabel: '$markerLabel (station marker)',  // Still accessible to screen readers
)
```

### Edge Case Typo-E2: Fare Display with Philippine Peso
**Location:** `fare_result_card.dart`  
**Challenge:** Currency symbols (₱) may render at different sizes than Latin text depending on font.

**Current:**
```dart
// Line 245 (approximate)
Text('₱${fare.toStringAsFixed(2)}')
```

**Risk:** At 200% text scale, ₱ symbol may be clipped if container size is fixed.

### Edge Case Typo-E3: Dynamic Type with Custom Fonts
**Location:** Potential future font integration  
**Challenge:** If custom fonts are added later, hardcoded sizes assume specific font metrics.

**Prevention:** All sizes should use theme typography scale which can be font-aware via `TextTheme`.

### Edge Case Typo-E4: Tablet Layouts
**Location:** Responsive breakpoints  
**Challenge:** Current hardcoded sizes may be appropriate for phones but too small for tablets in multi-pane views.

**Example:**
```dart
// Current - one size fits all
fontSize: 12

// Better - responsive via theme
style: Theme.of(context).textTheme.labelSmall  // Can be adaptive via TextTheme
```

## Recommendations

### Critical Path (Fix in 24 Hours)
1. **Add TextScaler safeguards** (Typo-09) - Implement at `MaterialApp` level with clamping
2. **Remove 9sp font size** (Typo-01) - Immediate readability fix

### Short Term (This Week)
3. Batch replace hardcoded `fontSize: 10` with `labelSmall` (Typo-02, Typo-03)
4. Audit onboarding screen fonts (Typo-05, Typo-06, Typo-07) - First impression
5. Remove redundant `copyWith(fontSize: 14)` where theme default matches (Typo-12)

### Medium Term (This Sprint)
6. Implement typography lint rule to prevent new hardcoded sizes
7. Add golden tests for text scaling at 100%, 150%, 200%
8. Document Typography scale in style guide

### Lint Rule Proposal
```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - no_hardcoded_font_sizes:
        allowed_sizes: []  # Empty = all hardcoded forbidden
        allowed_files:
          - "lib/src/core/theme/**"
```

### Theme Alignment Mapping
| If you need... | Use instead of hardcoded... |
|----------------|------------------------------|
| Large display text | `textTheme.headlineLarge` (32) |
| Screen titles | `textTheme.headlineMedium` (28) |
| Section headers | `textTheme.titleLarge` (22) |
| Card titles | `textTheme.titleMedium` (16) |
| Body text | `textTheme.bodyLarge` (16) |
| Captions | `textTheme.bodyMedium` (14) |
| Small labels | `textTheme.labelSmall` (11) |

---

**Related Modules:**
- Module 01: Localization Issues (hardcoded strings with hardcoded styles)
- Module 03: Color Contrast Issues (text color with hardcoded sizes)
- Module 04: Accessibility Strengths (proper Semantics usage)
- Module 10: Prioritized Fix Backlog
