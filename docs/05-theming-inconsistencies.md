# Module 05: Theming Inconsistencies

## Purpose
This module documents deviations from the established theme system in the Pasahe app. These inconsistencies create maintenance burden and user experience fragmentation.

## Findings Table

| ID | Severity | Location | Issue | Impact | Effort | Status |
|----|----------|----------|-------|--------|--------|--------|
| Theme-01 | **High** | `screens/map_picker_screen.dart:320` | Hardcoded `TextStyle(fontSize: 14)` | Bypasses theme typography scale | 5 min | 🔴 Open |
| Theme-02 | **High** | `screens/onboarding_screen.dart:192` | Hardcoded `TextStyle(fontSize: 24)` | Creates custom font size not in theme | 2 min | 🔴 Open |
| Theme-03 | **Medium** | `screens/reference_screen.dart:284` | Hardcoded `fontSize: 18` | Falls between theme headlineMedium (24) and titleLarge (22) | 2 min | 🔴 Open |
| Theme-04 | **Medium** | Multiple files | Mixed `textTheme` usage pattern | Some screens use theme, some don't | Ongoing | 🟡 Review |
| Theme-05 | **Medium** | `screens/settings_screen.dart:945` | Flag emoji with hardcoded fontSize: 28 | Language selector styling | 2 min | 🟡 Verify Necessary |
| Theme-06 | **Low** | `screens/main_screen.dart` | AppBar uses `Colors.transparent` | Disables M3 surface tint | 5 min | 🟡 Document |
| Theme-07 | **Low** | `screens/settings_screen.dart` | Custom divider styling | Slight deviation from M3 defaults | 2 min | 🟢 Acceptable |
| Theme-E1 | **Info** | `widgets/fare_result_card.dart` | Custom `shadowColor` calculation | Creative use, document | - | 🟢 Good Pattern |
| Theme-E2 | **Info** | `core/theme/app_theme.dart` | Custom M3 color mapping | Archipelago Blue theme is intentional | - | 🟢 Design Decision |

**Total Findings:** 7 inconsistencies + 2 intentional patterns  
**Theme Root:** `lib/src/core/theme/` - Strong foundation with deviations

## Evidence (Code Snippets)

### Finding Theme-01: Hardcoded TextStyle in Map Picker
**File:** `lib/src/presentation/screens/map_picker_screen.dart`  
**Line:** 320 (and 22 other locations)

```dart
// ❌ Inconsistent - bypasses theme
Text(
  'Pin location',
  style: const TextStyle(fontSize: 14),  // Theme bodyMedium is also 14 BUT...
)

// ✅ Would be consistent with:
Text(
  'Pin location',
  style: Theme.of(context).textTheme.bodyMedium,  // Respects theme
)
```

**Theme Alignment:**
```dart
// File: lib/src/core/theme/app_theme.dart
// Line ~180: textTheme definition
textTheme: const TextTheme(
  bodyMedium: TextStyle(
    fontSize: 14,  // Same value!
    fontWeight: FontWeight.normal,
    height: 1.5,
  ),
),
```

**The Issue:** Even though values match today, hardcoded values won't adapt to:
- Future theme redesigns
- Accessibility text scaling
- Dynamic type (iOS)

---

### Finding Theme-02: Onboarding Custom Typography
**File:** `lib/src/presentation/screens/onboarding_screen.dart`  
**Line:** 192 (and multiple)

```dart
// ❌ Custom sizing inconsistent with theme scale
Text(
  'Welcome to Pasahe',
  style: const TextStyle(
    fontSize: 24,  // Theme headlineLarge is 32, headlineMedium is 28
    fontWeight: FontWeight.w600,
  ),
)

// ✅ Should use:
Text(
  'Welcome to Pasahe',
  style: Theme.of(context).textTheme.headlineMedium,  // 28
)

// Or if 24 is required:
textTheme.headlineSmall ?? const TextStyle(fontSize: 24),  // Add to theme
```

**Impact:** Creates a "24px" tier that exists only in onboarding - inconsistent with rest of app.

---

### Finding Theme-03: Reference Screen Custom Size
**File:** `lib/src/presentation/screens/reference_screen.dart`  
**Line:** 284

```dart
// Line 284
Text(
  model.name,
  style: const TextStyle(fontSize: 18),  // Not in theme scale
)
```

**Theme Scale:**
| Token | Size | Status |
|-------|------|--------|
| headlineLarge | 32 | ✅ |
| headlineMedium | 28 | ✅ |
| titleLarge | 22 | ✅ |
| titleMedium | 16 | ✅ |
| **Custom** | **18** | **❓ Create `titleMedium` variant?** |

**Options:**
1. Use `titleLarge` (22) - slightly larger
2. Add `titleSmall` (18) to theme - extends scale
3. Use responsive sizing - add to theme

**Recommendation:** Option 2 - add `titleSmall` to theme for consistency.

---

### Finding Theme-04: Theme Usage Pattern Inconsistency
**Scope:** Across all presentation files

**Strong Theme Usage:**
```dart
// File: lib/src/core/theme/app_theme.dart
textTheme: const TextTheme(
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
  // ...
)

// Usage in settings_screen.dart:170
title: Semantics(
  header: true,
  child: Text(
    AppLocalizations.of(context)!.settingsTitle,
    style: theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  ),
),
```

**Weak/No Theme Usage:**
```dart
// Usage in map_picker_screen.dart (multiple locations)
style: const TextStyle(fontSize: 14),  // Bypasses theme

// Usage in onboarding_screen.dart:192
style: const TextStyle(fontSize: 24),  // Custom
```

**Audit Summary:**
| File | Theme Usage | Grade |
|------|-------------|-------|
| `settings_screen.dart` | Strong | A |
| `fare_result_card.dart` | Mixed | B |
| `map_picker_screen.dart` | Weak | D |
| `onboarding_screen.dart` | Weak | D |
| `reference_screen.dart` | Mixed | C |

---

### Finding Theme-05: Language Flag Emoji
**File:** `lib/src/presentation/screens/settings_screen.dart`  
**Line:** 945

```dart
// Line 945
leading: Text(flag, style: const TextStyle(fontSize: 28)),  // Emoji sizing
```

**Context:** This is displaying language flag emojis (🇺🇸, 🇵🇭).

**Analysis:**
- Flag emojis are unicode characters that render as system fonts
- 28sp size ensures legibility on accessibility-scaled devices
- May not respect theme text scale (emoji have different scaling rules)

**Verdict:** 🟡 **Probably acceptable** - emojis are special case, but could use:
```dart
textScaler: TextScaler.noScaling,  // Emojis don't need scaling
```

---

### Finding Theme-06: Transparent AppBar
**File:** `lib/src/presentation/screens/main_screen.dart`

```dart
AppBar(
  backgroundColor: Colors.transparent,  // Disables M3 surface tint
  elevation: 0,
)
```

**Impact:**
- Disables Material 3 elevation/surface tint
- Creates flat design aesthetic
- May be intentional for immersive content

**Recommendation:** Add comment if intentional:
```dart
AppBar(
  // Intentionally transparent for immersive map view behind
  backgroundColor: Colors.transparent,
)
```

---

### Finding Theme-07: Custom Divider Styling
**File:** `lib/src/presentation/screens/settings_screen.dart`

```dart
Divider(
  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
  height: 1,
  thickness: 1,
)
```

**Theme Default:**
```dart
// M3 default divider
Divider(
  color: colorScheme.outlineVariant,  // No alpha
  height: 16,  // Material default spacing
  thickness: 1,
)
```

**Verdict:** 🟢 **Acceptable customization** - subtle divider for dense settings list.

---

### Finding Theme-E1: Creative Theme Usage (Good Pattern)
**File:** `lib/src/presentation/widgets/fare_result_card.dart`

```dart
// ✅ GOOD: Using theme colors with creative application
Card(
  elevation: isRecommended ? 4 : 2,
  shadowColor: statusColor.withValues(alpha: 0.3),  // Creative use
)

// _getStatusColor() derives from theme:
Color _getStatusColor(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final transitColors = Theme.of(context).extension<TransitColors>();
  // Returns theme-derived color
}
```

**Why Good:** Uses theme as color source but applies creatively (custom shadow color).

---

### Finding Theme-E2: Intentional Theme Design (Archipelago Blue)
**File:** `lib/src/core/theme/app_theme.dart`

```dart
// ✅ INTENTIONAL: Custom theme palette
// Deep Teal primary paired with energetic orange accents
// Inspired by Philippine seas and islands

// Primary Colors (Deep Teal)
static const Color _lightPrimary = Color(0xFF006064);  // Deep Teal
static const Color _lightOnPrimary = Color(0xFFFFFFFF);
static const Color _lightPrimaryContainer = Color(0xFFE0F7FA);  // Coastal Foam

// Tertiary Colors (Lifevest Orange)
static const Color _lightTertiary = Color(0xFFFF6F00);  // Lifevest Orange
```

**Documentation Status:** 🟢 **Well documented** - Comments explain design intent.

## Edge Cases

### Edge Case Theme-E3: Responsive Typography
**Challenge:** No responsive typography breakpoints.

**Current:**
```dart
// Same text sizes on phone and tablet
titleLarge: TextStyle(fontSize: 22),  // Fixed
```

**Recommendation:** Consider responsive text:
```dart
// In theme builder
titleLarge: TextStyle(
  fontSize: isTablet(context) ? 24 : 22,
)
```

### Edge Case Theme-E4: Dynamic Type (iOS)
**Challenge:** iOS Dynamic Type not fully supported.

**Requirement:** On iOS, text sizes respond to:
- Settings → Display & Brightness → Text Size
- Settings → Accessibility → Larger Text

**Current:** No evidence of `textScaleFactor` clamping or iOS dynamic type handling.

**Note:** Related to Typo-09 (missing text scaling) - see Module 02.

### Edge Case Theme-E5: Font Loading
**Challenge:** Custom fonts could be loaded but no system.

**Current:** Uses system fonts (device default).

**Future Option:**
```dart
textTheme: TextTheme(
  bodyMedium: GoogleFonts.notoSans(
    fontSize: 14,
    // Provides better Philippine language support
  ),
).apply(
  fontFamily: 'Roboto',  // Android default
  fontFamilyFallback: ['Noto Sans', 'Arial'],
)
```

## Recommendations

### Immediate Actions
1. **Map Picker Theme Audit** (Theme-01) - Replace 22 instances of hardcoded TextStyle
2. **Onboarding Typography Fix** (Theme-02) - Use theme tokens or add titleSmall

### Short Term
3. **Create Typography Token Cheat Sheet:**
```markdown
# Typography Mapping
| Your Text | Use This Token |
|-----------|----------------|
| Screen title | headlineLarge (32) |
| Section header | headlineMedium (28) |
| Card title | titleLarge (22) |
| List item title | titleMedium (16) |
| List item subtitle | bodyMedium (14) |
| Button text | labelLarge (14) |
| Caption | labelSmall (11) |

NEVER use: fontSize: 24, fontSize: 18, fontSize: 9
```

### Lint Rule Proposal
```yaml
# custom_lint configuration
dart_code_metrics:
  rules:
    - prefer-theme-text-style:
        severity: warning
    - no-hardcoded-text-style:
        severity: error
        exclude:
          - "lib/src/core/theme/**"
```

### Theme Audit Script
```bash
# Find all manual TextStyle(fontSize: ...) usage
grep -rn "TextStyle(fontSize:" lib/src/presentation --include="*.dart"

# Should return empty (after fixes)
# All should use Theme.of(context).textTheme.*
```

---

**Related Modules:**
- Module 02: Typography Issues (hardcoded font sizes)
- Module 03: Color Contrast Issues (theme color bypass)
- Module 04: Accessibility Strengths (ThemeExtension pattern)
- Module 10: Prioritized Fix Backlog
