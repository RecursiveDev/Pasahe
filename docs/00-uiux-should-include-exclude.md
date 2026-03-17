# Module 00: UI/UX Should Include / Should NOT Include

## Purpose
This module provides an explicit consolidated checklist of UI/UX patterns that **SHOULD** and **SHOULD NOT** be included in the Pasahe app. Use this as a quick reference during development and code review.

**Related:** [01-localization-issues](./01-localization-issues.md) | [02-typography-issues](./02-typography-issues.md) | [03-color-contrast-issues](./03-color-contrast-issues.md) | [11-navigation-error-feedback-patterns](./11-navigation-error-feedback-patterns.md)

---

## SHOULD NOT Include ❌

### Typography & Text

| Pattern | Finding ID | Evidence | Why Avoid |
|---------|------------|----------|-----------|
| Hardcoded font sizes < 11sp | Typo-01, Typo-02 | `passenger_bottom_sheet.dart:127` - `fontSize: 12` in subtitle (borderline) | WCAG 1.4.4 failure; system text scale breaks layout |
| Fixed text scaling without safeguards | Typo-09 | `splash_screen.dart:55-70` - Animation text lacks TextScaler awareness | Users with vision impairment cannot read content |
| Non-semantic text styling | Typo-03, Typo-04 | Multiple screens using `TextStyle(fontSize: X)` directly | Inconsistent with Material 3 design system |

### Color & Theming

| Pattern | Finding ID | Evidence | Why Avoid |
|---------|------------|----------|-----------|
| Raw `Colors.black` / `Colors.white` | Color-01, Color-02 | `error_message_banner.dart:21` - `color: colorScheme.error` ✅ (good) vs hardcoded found elsewhere | Breaks dark mode; non-themeable |
| Alpha values without semantic meaning | Color-08 | Various `withOpacity()` calls | Fragile; use `colorScheme` containers instead |
| Missing error container colors | Color-03 | Some widgets use `backgroundColor: Colors.red` | Should use `colorScheme.errorContainer` |

### Localization

| Pattern | Finding ID | Evidence | Why Avoid |
|---------|------------|----------|-----------|
| Hardcoded user-facing strings | L10n-01 through L10n-12 | `offline_status_banner.dart:50-52` - Hardcoded English strings | App targets Tagalog/English bilingual users |
| Non-internationalized error messages | L10n-02 | `main_screen.dart:296-301` - `'Failed to get location'` | Error messages must be localized |
| Date/number formatting without locale | L10n-11 | Currency displays may lack proper PHP formatting | Financial data requires cultural formatting |

### Accessibility

| Pattern | Finding ID | Evidence | Why Avoid |
|---------|------------|----------|-----------|
| Interactive elements without semantics | A11y-03 | Map picker buttons may lack `tooltip` or `semanticsLabel` | Screen reader users cannot identify controls |
| Color-only status indicators | A11y-02 | Status banners rely solely on color | Colorblind users cannot distinguish states |
| Missing loading state announcements | A11y-05 | `_isLoadingAddress` transitions lack semantics | Screen reader users don't know loading started |

### Navigation & Feedback

| Pattern | Finding ID | Evidence | Why Avoid |
|---------|------------|----------|-----------|
| Silent failures (no user feedback) | Nav-01 | `map_picker_screen.dart:178-209` - Address loading errors may be silent | Users don't know something failed |
| No retry mechanism for recoverable errors | Nav-03 | `region_download_screen.dart:360` - Retry exists but not consistently applied | Users stuck on error states |
| Missing back gesture handling | Nav-05 | Bottom sheets may not handle back properly on Android | Unexpected dismissal behavior |
| Generic error messages | Nav-02 | `main_screen.dart:344-347` - Generic `'Failed to get address'` | Doesn't help user resolve issue |

### Network & Offline

| Pattern | Finding ID | Evidence | Why Avoid |
|---------|------------|----------|-----------|
| No offline indication | Offline-01 | Screens without `OfflineStatusBanner` | Users don't know why features fail |
| Rate limit without UX feedback | Map-01 | `geocoding_service.dart:47-60` - Throttle exists but no UI | Users spam search, get no results, confused |
| Blocking loading without progress | Offline-03 | `region_download_screen.dart:329-330` - Binary loading state | Large downloads (>500MB) need progress |

---

## SHOULD Include ✅

### Typography & Text

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| Theme-derived text styles | Typo-S1 | `passenger_bottom_sheet.dart:45` - `textTheme.titleLarge` | Use `Theme.of(context).textTheme` exclusively |
| TextScaler-aware layouts | Typo-S2 | `passenger_bottom_sheet.dart:20-30` - `MediaQuery.viewInsets` usage | Wrap in `LayoutBuilder` or overflow handlers |
| Semantic font weights | Typo-S3 | `passenger_bottom_sheet.dart:127` - `FontWeight.w600` | Use `FontWeight` constants, not raw numbers |
| Proper text contrast | Color-S1 | `error_message_banner.dart:27` - `colorScheme.onErrorContainer` | Always use on-* colors for text on containers |

**Evidence - Good Pattern (Theme-derived styling):**
```dart
// File: lib/src/presentation/widgets/main_screen/passenger_bottom_sheet.dart:44-48
textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
```

### Color & Theming

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| ColorScheme usage | Color-S2 | `passenger_bottom_sheet.dart:44` - `colorScheme.outlineVariant` | Use `Theme.of(context).colorScheme` |
| Container colors with proper contrast | Color-S3 | `passenger_bottom_sheet.dart:83-88` - `primaryContainer.withValues(alpha: 0.3)` | Alpha values only on container colors |
| Theme-aware error states | Color-S4 | `error_message_banner.dart:16` - `colorScheme.errorContainer` | Use semantic error containers |

**Evidence - Good Pattern (Semantic Error Container):**
```dart
// File: lib/src/presentation/widgets/main_screen/error_message_banner.dart:16-20
decoration: BoxDecoration(
  color: colorScheme.errorContainer,
  borderRadius: BorderRadius.circular(12),
),
```

### Localization

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| AppLocalizations for all strings | L10n-S1 | `main_screen.dart:367` - `AppLocalizations.of(context)!.routeSavedMessage` | Every user-facing string via `.arb` files |
| Locale-aware formatting | L10n-S2 | Currency formatting with proper locale | Use `NumberFormat` with locale |
| RTL layout support | L10n-S3 | Widgets using `EdgeInsetsDirectional` | Avoid absolute left/right where possible |

### Accessibility

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| Semantic labels on icons | A11y-S1 | Icon buttons with `tooltip` parameter | Always provide `tooltip` for icon buttons |
| Loading state announcements | A11y-S2 | `AnimatedSwitcher` for state changes | Wrap in `Semantics` with proper labels |
| Proper touch targets | A11y-S3 | `passenger_bottom_sheet.dart:147-150` - `minWidth: 40, minHeight: 40` | Minimum 48dp touch targets |

**Evidence - Good Pattern (Accessible Touch Targets):**
```dart
// File: lib/src/presentation/widgets/main_screen/passenger_bottom_sheet.dart:147-150
IconButton(
  icon: Icon(Icons.remove, /* ... */),
  onPressed: onDecrement,
  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
)
```

### Navigation & Feedback

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| Modal bottom sheets with handles | Nav-S1 | `passenger_bottom_sheet.dart:50-57` - Drag handle | Include visual handle for discoverability |
| SnackBar for transient messages | Nav-S2 | `main_screen.dart:367-374` - Route saved confirmation | Use `SnackBarBehavior.floating` with shape |
| Dialog for destructive actions | Nav-S3 | `region_download_screen.dart:139-151` - Delete confirmation | Confirm irreversible actions |
| Smooth loading transitions | Nav-S4 | `map_picker_screen.dart:792-808` - `AnimatedSwitcher` | Transition between loading/content/error |
| Retry buttons for errors | Nav-S5 | `region_download_screen.dart:360` - Retry button | Allow user-initiated recovery |

**Evidence - Good Pattern (Modal with Handle):**
```dart
// File: lib/src/presentation/widgets/main_screen/passenger_bottom_sheet.dart:50-57
Center(
  child: Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: colorScheme.outlineVariant,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
),
```

**Evidence - Good Pattern (Floating SnackBar):**
```dart
// File: lib/src/presentation/screens/main_screen.dart:367-374
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(AppLocalizations.of(context)!.routeSavedMessage),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);
```

### Network & Offline

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| Offline status banners | Offline-S1 | `offline_status_banner.dart:22-76` - Connectivity-aware banner | Show on all screens with network dependency |
| Rate limit feedback | Map-S1 | `geocoding_service.dart:47-60` - Throttle with debounce | Combine with UI messaging |
| Progressive loading states | Offline-S2 | `map_picker_screen.dart:46-47` - `ValueNotifier<bool>` for states | Multiple loading states (search vs address) |
| Cached data fallbacks | Offline-S3 | `offline_mode_service.dart` - Offline-first patterns | Graceful degradation with cache |

**Evidence - Good Pattern (Offline Status Banner):**
```dart
// File: lib/src/presentation/widgets/main_screen/offline_status_banner.dart:22-76
class OfflineStatusBanner extends StatelessWidget {
  final ConnectivityStatus status;
  // ... displays contextual message based on connectivity state
  // with "Go Online" button for manual offline mode
}
```

### Animation & Motion

| Pattern | Finding ID | Evidence | Implementation |
|---------|------------|----------|----------------|
| Smooth splash animations | Anim-S1 | `splash_screen.dart:55-70` - Staggered animations | Use `AnimationController` with curves |
| Map pin animations | Anim-S2 | `map_picker_screen.dart:62-73` - Pin bounce animation | Physical motion with `Curves.bounceOut` |
| Loading shimmer/skeleton | Anim-S3 | To be implemented | Placeholder UI during content load |

**Evidence - Good Pattern (Pin Animation):**
```dart
// File: lib/src/presentation/screens/map_picker_screen.dart:62-73
_pinBounceAnimation = Tween<double>(begin: 0, end: -20).animate(
  CurvedAnimation(
    parent: _pinAnimationController,
    curve: Curves.easeOut,
    reverseCurve: Curves.bounceOut,
  ),
);
```

---

## Quick Reference Checklist

### Before Submitting PR

- [ ] No hardcoded strings in new code (use `AppLocalizations`)
- [ ] No raw `Colors.xxx` (use `colorScheme`)
- [ ] No fixed font sizes without TextScaler handling
- [ ] Touch targets minimum 48dp
- [ ] Icon buttons have tooltips
- [ ] Loading states visible to user
- [ ] Error states have actionable messages
- [ ] Offline status considered
- [ ] Dialogs used for destructive actions
- [ ] SnackBars used for confirmations

### Code Review Focus Areas

| Area | Check For |
|------|-----------|
| Typography | Theme-based, scalable, semantic weights |
| Color | ColorScheme, proper contrast, no hardcoded values |
| Localization | All strings externalized, RTL-safe layouts |
| Accessibility | Touch targets, semantics, color-independent indicators |
| Navigation | Proper back handling, clear transitions, state preservation |
| Feedback | Loading states, error messages, retry options |
| Offline | Status visibility, graceful degradation, cache usage |

---

## Related Findings

| Module | Relevant Findings |
|--------|-------------------|
| 01-localization-issues | L10n-01 through L10n-12 |
| 02-typography-issues | Typo-01, Typo-02, Typo-03, Typo-09 |
| 03-color-contrast-issues | Color-01, Color-02, Color-03, Color-08 |
| 04-accessibility-strengths | A11y-S1 through A11y-S3 |
| 06-map-offline-edge-cases | Map-01, Map-03, Map-04, Offline-01 |
| 11-navigation-error-feedback-patterns | Nav-01 through Nav-S5 |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-17 | Initial should/should not checklist |
