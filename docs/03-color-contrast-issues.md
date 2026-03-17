# Module 03: Color and Contrast Issues

## Purpose
This module documents hardcoded color values, contrast risks, and theme non-compliance in the Pasahe app. It covers both aesthetic consistency and WCAG contrast requirements for accessibility.

## Findings Table

| ID | Severity | Location | Issue | WCAG Impact | Effort | Status |
|----|----------|----------|-------|-------------|--------|--------|
| Color-01 | **High** | `screens/map_picker_screen.dart:391,411` | `Colors.black.withValues(alpha: 0.1)` | Hardcoded, may not adapt to dark mode | 5 min | 🔴 Open |
| Color-02 | **High** | `screens/map_picker_screen.dart:496` | `Colors.black.withValues(alpha: 0.2)` | Shadow/backdrop color hardcoded | 5 min | 🔴 Open |
| Color-03 | **High** | `screens/map_picker_screen.dart:725` | `Colors.black.withValues(alpha: 0.15)` | Divider/shadow color hardcoded | 5 min | 🔴 Open |
| Color-04 | **High** | `screens/offline_menu_screen.dart:291,320` | `Colors.white.withValues(alpha: 0.2/0.9)` | Assumes dark background | 10 min | 🔴 Open |
| Color-05 | **High** | `screens/offline_menu_screen.dart:296,307` | `Colors.white` solid | May be invisible on light theme | 5 min | 🔴 Open |
| Color-06 | **Medium** | `screens/map_picker_screen.dart:379` | `Colors.transparent` background | Legitimate use but verify elevation | 2 min | 🟡 Verify |
| Color-07 | **Medium** | `screens/offline_menu_screen.dart:204` | `surfaceTintColor: Colors.transparent` | Disables Material 3 tint | 2 min | 🟡 Design Review |
| Color-08 | **Medium** | Multiple files | `withValues(alpha: 0.1-0.3)` patterns | Transparency may reduce contrast below WCAG | 15 min | 🔴 Open |
| Color-09 | **Low** | `screens/map_picker_screen.dart:320,325` | Hardcoded error icon colors | Uses theme scheme but hardcoded `Icons.warning_amber_rounded` | 2 min | 🟢 Acceptable |
| Color-10 | **Low** | `screens/map_picker_screen.dart:353` | `colorScheme.surface.withValues` | Acceptable use of theme with alpha | 🟢 OK |
| Color-E1 | **Medium** | `widgets/fare_result_card.dart` | `accentColor.withValues(alpha: 0.15)` | Theme-based with transparency | 🟢 Pattern OK |

**Total Findings:** 10 distinct issues + 1 pattern verification  
**WCAG Reference:** 1.4.3 Contrast (Minimum) Level AA requires 4.5:1 for normal text, 3:1 for large text

## Evidence (Code Snippets)

### Finding Color-01, Color-02, Color-03: Hardcoded `Colors.black` Usage
**File:** `lib/src/presentation/screens/map_picker_screen.dart`

```dart
// Line 391
BoxDecoration(
  color: Colors.black.withValues(alpha: 0.1),  // Color-01
  borderRadius: BorderRadius.circular(8),
)

// Line 411 - same pattern
BoxDecoration(
  color: Colors.black.withValues(alpha: 0.1),  // Color-01
  borderRadius: BorderRadius.circular(12),
)

// Line 496
BoxDecoration(
  color: Colors.black.withValues(alpha: 0.2),  // Color-02
  borderRadius: BorderRadius.circular(16),
)

// Line 725
BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),  // Color-03
      blurRadius: 8,
    ),
  ],
)
```

**Problem:** `Colors.black` doesn't adapt to dark mode. In dark themes:
- `Colors.black` with alpha becomes gray on dark surfaces
- May create unintended visual hierarchy
- Breaks Material 3 elevation/tint model

**Required Fix:**
```dart
// ✅ Use theme onSurface with alpha
BoxDecoration(
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
)

// Or use surfaceContainer for themed background layers
BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
)
```

---

### Finding Color-04, Color-05: Hardcoded `Colors.white` Usage
**File:** `lib/src/presentation/screens/offline_menu_screen.dart`

```dart
// Line 291 - assumes gradient background is dark
BoxDecoration(
  color: Colors.white.withValues(alpha: 0.2),  // Color-04
)

// Line 296 - solid white
BoxDecoration(
  color: Colors.white,  // Color-05
)

// Line 307 - solid white
BoxDecoration(
  color: Colors.white,  // Color-05
)

// Line 320 - light translucent
BoxDecoration(
  color: Colors.white.withValues(alpha: 0.9),  // Color-04
)
```

**Context:** These appear in the offline menu which uses a custom gradient background.

**Dark Mode Risk:** If user switches to light theme, `Colors.white` becomes invisible on light surfaces.

**Required Fix:**
```dart
// Theme-aware approach
BoxDecoration(
  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
)

// Or for card backgrounds:
BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
)
```

---

### Finding Color-06: `Colors.transparent` Backgrounds
**File:** `lib/src/presentation/screens/map_picker_screen.dart`  
**Line:** 379

```dart
// Line 379
Scaffold(
  backgroundColor: Colors.transparent,  // Color-06
)
```

**Evaluation:** This MAY be intentional for map overlay where the map shows through.

**Verification Required:**
```dart
// Check if body has sufficient contrast without scaffold background
// If map is always rendered first, this is acceptable
// BUT consider semantic background for accessibility:
Scaffold(
  backgroundColor: Colors.transparent,
  // Ensure content containers have their own backgrounds
)
```

**Verdict:** 🟡 Likely acceptable with map overlay, but document inline why transparent is used.

---

### Finding Color-07: Disabled Surface Tint
**File:** `lib/src/presentation/screens/offline_menu_screen.dart`  
**Line:** 204

```dart
Scaffold(
  surfaceTintColor: Colors.transparent,  // Color-07
)
```

**Context:** In Material 3, `surfaceTintColor` applies elevation color overlay. Setting to `Colors.transparent` explicitly disables this.

**Design Decision:** May be intentional for custom gradient background, but should be documented.

**Recommendation:** Add comment:
```dart
Scaffold(
  // Disable M3 surface tint to allow custom gradient background
  surfaceTintColor: Colors.transparent,
)
```

---

### Finding Color-08: Global Alpha Pattern Review
**Scope:** All files with `withValues(alpha: ...)`  
**Pattern Count:** 20+ instances

**Risk:** Any alpha less than ~0.6 on text may fail WCAG contrast requirements.

**Evidence Pattern:**
```dart
// Risky patterns found:
alpha: 0.1  // 10% opacity - likely fails contrast
alpha: 0.15 // 15% opacity - likely fails contrast
alpha: 0.2  // 20% opacity - likely fails contrast
alpha: 0.3  // 30% opacity - borderline for large text
```

**Safe Alpha Thresholds for Backgrounds:**
| Use Case | Min Alpha | Rationale |
|----------|-----------|-----------|
| Disabled text | 0.38 | M3 standard |
| Placeholder text | 0.38 | M3 standard |
| Divider/subtle borders | 0.12 | M3 standard |
| Hover/focus states | 0.08 | M3 standard |
| Pressed states | 0.12 | M3 standard |

**Unsafe Pattern Found:**
```dart
// Line 583 in reference_screen.dart
Color(0xFF000000).withValues(alpha: 0.8)  // Typo-10 location - text at 80% opacity
```

This is actually at 80% opacity which is acceptable, but the pattern should be theme-based.

---

### Finding Color-09: Error Icon Colors (Acceptable)
**File:** `lib/src/presentation/screens/map_picker_screen.dart`  
**Lines:** 320, 325

```dart
// Line 320
Container(
  color: colorScheme.errorContainer,  // ✅ Theme-based
  child: Icon(
    Icons.warning_amber_rounded,
    color: colorScheme.error,  // ✅ Theme-based
  ),
)
```

**Verdict:** 🟢 **ACCEPTABLE** - Uses theme `colorScheme` correctly. Hardcoded icon choice is fine (Material Icons are icon font, not color).

---

### Finding Color-10: Acceptable Theme Usage
**File:** `lib/src/presentation/screens/map_picker_screen.dart`  
**Line:** 353

```dart
// ✅ ACCEPTABLE
BoxDecoration(
  color: colorScheme.surface.withValues(alpha: 0.8),  // Theme-based with alpha
)
```

**Pattern:** Using theme color with alpha is acceptable when the semantic relationship to theme is preserved.

---

### Finding Color-E1: Theme-Based Alpha Pattern (Good Example)
**File:** `lib/src/presentation/widgets/fare_result_card.dart`

```dart
// ✅ GOOD - theme-based with alpha
Container(
  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.15),  // Theme-derived with alpha
    shape: BoxShape.circle,
  ),
)
```

**Pattern:** Using `statusColor` (which comes from theme via `_getStatusColor`) with alpha is consistent pattern. Documented as `Color-E1` for reference.

## Edge Cases

### Edge Case Color-E2: Container Background vs. Text Contrast
**Location:** `fare_result_card.dart`  
**Challenge:** Card uses `colorScheme.surfaceContainerLowest` + elevation shadow.

**Current:**
```dart
Card(
  elevation: isRecommended ? 4 : 2,
  shadowColor: statusColor.withValues(alpha: 0.3),  // Custom shadow color
)
```

**Risk:** Shadow color with high chroma (`statusColor`) may create color confusion for users with color vision deficiencies.

**Mitigation:** Add border for non-color cue:
```dart
Card(
  shape: RoundedRectangleBorder(
    side: isRecommended 
      ? BorderSide(color: statusColor, width: 2)  // ✅ Non-color indicator
      : BorderSide.none,
  ),
)
```

### Edge Case Color-E3: Map Tiles and Accessibility
**Location:** Map screens  
**Challenge:** Map tiles from OpenStreetMap may have insufficient contrast in certain regions.

**Current:** No custom tile styling for accessibility.

**Risk:** Users with low vision may struggle to distinguish map features.

**Mitigation:** Document known limitation in accessibility statement. Consider high-contrast map style option in settings.

### Edge Case Color-E4: Dark Mode Color Inversion Edge Cases
**Challenge:** Some hardcoded colors may "accidentally" work in both themes.

**Example:**
```dart
Colors.black.withValues(alpha: 0.1)  // In dark mode, becomes gray overlay
```

This may "look fine" in dark mode but breaks semantic consistency. Screen readers may describe wrong color relationships.

**Test Pattern:**
```bash
# Find all withValues alpha usage
grep -rn "withValues(alpha:" lib/src/presentation --include="*.dart"

# Review each for theme compliance
```

### Edge Case Color-E5: Gradient Backgrounds
**Location:** `offline_menu_screen.dart`  
**Challenge:** Gradients use hardcoded color stops.

**Current (likely pattern, not in provided snippets):**
```dart
BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Color(0xFF006064),  // Deep Teal - hardcoded
      Color(0xFF0097A7),  // Pacific Blue - hardcoded
    ],
  ),
)
```

**Risk:** Gradients don't automatically adapt to dark mode.

**Mitigation:** Use theme-aware gradient constructor:
```dart
BoxDecoration(
  gradient: Theme.of(context).brightness == Brightness.dark
    ? TransitColors.darkGradient  // From ThemeExtension
    : TransitColors.lightGradient,
)
```

## Recommendations

### High Priority (Fix This Sprint)
1. **Replace `Colors.black` with theme onSurface** (Color-01, Color-02, Color-03)
2. **Replace `Colors.white` with theme surface** (Color-04, Color-05)
3. **Add contrast validation to CI** - Automated check for text contrast ratios

### Medium Priority (Next Sprint)
4. **Document `Colors.transparent` usage** (Color-06, Color-07) with inline comments
5. **Standardize alpha usage** - Create design tokens for common alpha values
6. **Test dark mode contrast** - Systematic review of all screens in dark mode

### Low Priority (Maintenance)
7. **Add high-contrast map theme** option for accessibility
8. **Implement dynamic contrast** detection (Android 12+)

### Code Pattern Standards

**Approved Pattern:**
```dart
// Theme-based colors with semantic meaning
color: Theme.of(context).colorScheme.errorContainer
color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)  // Disabled
```

**Deprecated Pattern:**
```dart
// Hardcoded colors
color: Colors.white
color: Colors.black.withValues(alpha: 0.1)
color: Color(0xFF006064)  // Use theme constant instead
```

### Theme Extension Alignment
The app uses `TransitColors` ThemeExtension (see `lib/src/core/theme/transit_colors.dart`). This is a **strength**. The issues documented here are **deviations** from this pattern.

**Verification:**
```bash
# Count TransitColors vs Color() usage
grep -rn "TransitColors" lib/src/presentation --include="*.dart" | wc -l  # Good: ~15
grep -rn "Color(0x" lib/src/presentation --include="*.dart" | wc -l       # Bad: ~40 (in theme files ok)
grep -rn "Colors\." lib/src/presentation --include="*.dart" | wc -l       # Review: ~50
```

---

**Related Modules:**
- Module 04: Accessibility Strengths (TransitColors ThemeExtension usage)
- Module 05: Theming Inconsistencies (pattern coverage)
- Module 10: Prioritized Fix Backlog
