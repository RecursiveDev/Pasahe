# Module 10: Prioritized Fix Backlog

## Purpose
This document consolidates all findings from the UI/UX and Code Health audits into a prioritized action plan. Items are ranked by impact, effort, and risk to optimize development velocity.

## Summary Statistics

| Category | Total Findings | Critical | High | Medium | Low |
|----------|---------------|----------|------|--------|-----|
| **UI/UX** | 34 | 1 | 12 | 14 | 7 |
| **Code Health** | 14 | 1 | 5 | 5 | 3 |
| **Navigation/Error/Feedback** | **23** | **0** | **6** | **10** | **7** |
| **TOTAL** | **71** | **2** | **23** | **29** | **17** |

---

## Priority Matrix

### P0 - Fix Immediately (This Week)

| ID | Module | Finding | Effort | Impact | Owner |
|----|--------|---------|--------|--------|-------|
| **P0-1** | 02-Typography | `fontSize: 9` - Critical accessibility violation (Typo-01) | 2 min | **Critical** - WCAG 1.4 failure | Accessibility |
| **P0-2** | 08-Test-Code │ Invalid override `_handleConnectivityChange` (Test-01) | 30 min | **High** - Build risk | Backend |
| **P0-3** | 02-Typography | Missing TextScaler safeguards (Typo-09) | 30 min | **Critical** - System text scale breaks app | Accessibility |
| **P0-4** | 07-Dead-Code │ Remove unused `_connectivityService` field (Dead-01) | 5 min | **High** - Code clarity | Backend |
| **P0-5** | **11-Nav-Error** | **Rate limit without UX feedback (Rate-01)** | 2 hours | **Critical** - User confusion | Mobile |
| **P0-6** | **11-Nav-Error** | **Silent failures on address lookup (Err-04)** | 1 hour | **High** - User unaware of errors | Mobile |

---

### P1 - High Priority (Next 2 Weeks)

| ID | Module | Finding | Effort | Impact | Owner |
|----|--------|---------|--------|--------|-------|
| **P1-1** | 01-L10n | Hardcoded error messages in main screens (L10n-01, L10n-02) | 20 min | **High** - Untranslated user-facing errors | i18n |
| **P1-2** | 01-L10n | Onboarding hardcoded strings (L10n-04) | 1 hour | **High** - First impression for Tagalog users | i18n |
| **P1-3** | 02-Typography | 10sp font sizes in chips/badges (Typo-02, Typo-03) | 10 min | **Medium** - Low readability | UI |
| **P1-4** | 08-Test-Code | Fix setter override in mocks (Test-02) | 20 min | **Medium** - Test stability | QA |
| **P1-5** | 08-Test-Code | Remove `print()` statements in tests (Test-03) | 10 min | **Low** - CI log hygiene | QA |
| **P1-6** | 07-Dead-Code | Remove `cupertino_icons` dependency (Dep-01) | 5 min | **Medium** - Bundle size | DevOps |
| **P1-7** | 07-Dead-Code | Remove redundant asset declaration (Dep-02) | 2 min | **Low** - Maintenance | DevOps |
| **P1-8** | 03-Color | Replace `Colors.black` with theme (Color-01, Color-02, Color-03) | 30 min | **Medium** - Dark mode consistency | UI |
| **P1-9** | **11-Nav-Error** | **Permission denied UX with settings deep-link (Perm-02, Perm-03)** | 2 hours | **High** - User recovery path | Mobile |
| **P1-10** | **11-Nav-Error** | **Generic error messages not actionable (Err-01)** | 1 hour | **High** - User confusion | Mobile |
| **P1-11** | **11-Nav-Error** | **Navigation result without error channel (Nav-01)** | 2 hours | **Medium** - Error context lost | Mobile |

---

### P2 - Medium Priority (This Month)

| ID | Module | Finding | Effort | Impact | Owner |
|----|--------|---------|--------|--------|-------|
| **P2-1** | 01-L10n | Batch conversion - Settings screen strings (L10n-07) | 2 hours | **Medium** - Consistency | i18n |
| **P2-2** | 01-L10n | Region download/delete operations (L10n-10) | 2 hours | **Medium** - Feature i18n | i18n |
| **P2-3** | 02-Typography | Onboarding screen typography alignment (Typo-05, Typo-06, Typo-07) | 1 hour | **Medium** - Design system | UI |
| **P2-4** | 03-Color | Replace `Colors.white` with theme (Color-04, Color-05) | 45 min | **Medium** - Dark mode | UI |
| **P2-5** | 06-Map-Offline │ Storage pre-check for downloads (Offline-01) | 2 hours | **High** - UX on failure | Mobile |
| **P2-6** | 06-Map-Offline │ OSRM timeout fallback UX (Map-04) | 2 hours | **Medium** - User understanding | Mobile |
| **P2-7** | 09-Dep-Red │ Run full `dart analyze` for unused items | 30 min | **Medium** - Maintenance | Backend |
| **P2-8** | 05-Theme │ Map picker theme audit (Theme-01) | 2 hours | **Medium** - Consistency | UI |
| **P2-9** | **11-Nav-Error** | **Inconsistent retry patterns (Nav-03, Retry-03)** | 2 hours | **Medium** - Error recovery | Mobile |
| **P2-10** | **11-Nav-Error** | **Empty state patterns (Empty-01, Empty-02)** | 3 hours | **Medium** - UX polish | Design |
| **P2-11** | **11-Nav-Error** | **Download progress indicator (Load-03)** | 4 hours | **Medium** - Large download UX | Mobile |

---

### P3 - Low Priority (Backlog)

| ID | Module | Finding | Effort | Impact | Owner |
|----|--------|---------|--------|--------|-------|
| **P3-1** | 01-L10n | Travel options sort labels (L10n-12) | 30 min | **Low** | i18n |
| **P3-2** | 02-Typography | Flag emoji sizing (Theme-05) | 5 min | **Low** | UI |
| **P3-3** | 05-Theme │ Reference screen font size 18 (Theme-03) | 30 min | **Low** | UI |
| **P3-4** | 06-Map-Offline │ Manual coordinate UX in rural areas (Map-03) | 1 hour | **Low** | Product |
| **P3-5** | 06-Map-Offline │ Offline mode tile visualization (Map-05) | 3 hours | **Low** | Design |
| **P3-6** | 06-Map-Offline │ Cross-region behavior documentation (Map-06) | 30 min | **Low** | Docs |
| **P3-7** | 08-Test-Code | Mock completeness audit (Test-04) | 4 hours | **Medium** | QA |
| **P3-8** | 03-Color | Alpha usage review (Color-08) | 2 hours | **Low** | UI |
| **P3-9** | **11-Nav-Error** | **Haptic feedback implementation (Haptic-01, Haptic-02)** | 2 hours | **Low** - UX enhancement | Mobile |
| **P3-10** | **11-Nav-Error** | **Back gesture handling for modals (Nav-05)** | 1 hour | **Low** - Android UX | Mobile |
| **P3-11** | **11-Nav-Error** | **Loading state enhancements (Load-04)** | 2 hours | **Low** - Polish | UI |

---

## Sprint Planning

### Sprint 1: Critical Path (1-2 devs)

**Goal:** Fix P0 items (accessibility critical + test code critical)

**Backlog:**
```markdown
## Sprint 1: Critical Accessibility + Test Fixes

### Day 1-2: Typography Critical
- [ ] P0-1: Remove `fontSize: 9` → Use theme
- [ ] P0-3: Implement TextScaler safeguards at MaterialApp level
- [ ] P1-3: Fix 10sp instances in chips

### Day 3: Test Code Fixes
- [ ] P0-2: Fix invalid override in mocks
- [ ] P1-4: Fix setter override in mocks
- [ ] P1-5: Replace print with debugPrint

### Day 4: Dead Code
- [ ] P0-4: Remove _connectivityService
- [ ] P1-6: Remove cupertino_icons dependency
- [ ] P1-7: Fix asset redundancy

### Day 5: Testing + CI
- [ ] Run full test suite
- [ ] Fix regression issues
- [ ] Update CI to fail on avoid_print
```

**Estimated Story Points:** 13 points (P0 + P1 critical)

---

### Sprint 2: Localization Foundation (1-2 devs)

**Goal:** Address user-facing untranslated strings

**Backlog:**
```markdown
## Sprint 2: Localization Critical

### Week 1
- [ ] P1-1: Localize error messages (L10n-01, L10n-02)
- [ ] P1-2: Localize onboarding flow

### Week 2
- [ ] P2-1: Settings screen batch localization
- [ ] P2-2: Region download localization

### Throughout
- [ ] Add l10n keys for errors found during onboarding work
- [ ] Update app_tl.arb with verified Tagalog translations
```

**Estimated Story Points:** 21 points

---

### Sprint 3: UI Polish (1 dev)

**Goal:** Systematize typography and color usage

**Backlog:**
```markdown
## Sprint 3: UI Consistency

- [ ] P1-8: Replace Colors.black with theme
- [ ] P2-3: Onboarding typography alignment
- [ ] P2-4: Replace Colors.white with theme
- [ ] P2-8: Map picker theme audit
- [ ] P3-2: Document typography token usage
```

**Estimated Story Points:** 13 points

---

### Sprint 4: Offline UX (1 dev)

**Goal:** Improve offline/map edge cases

**Backlog:**
```markdown
## Sprint 4: Offline Experience

- [ ] P2-5: Add storage pre-check before download
- [ ] P2-6: Show fallback accuracy to users
- [ ] P3-4: Better UX for reverse geocode failure
- [ ] P3-5: Visual cache status on map
```

**Estimated Story Points:** 21 points

---

## Risk Mitigation

### Risk: Testing Coverage
**Mitigation:**
- Add golden tests for TextScaler at 100%, 150%, 200%
- Add integration test for localization language switch
- Add CI check: `flutter analyze --fatal-infos`

### Risk: Tagalog Translation Quality
**Mitigation:**
- Work with native speaker for verification
- Use `flutter gen-l10n --output-localization-file` with placeholders
- Test with TalkBack in Tagalog

### Risk: Theme Changes Breaking UI
**Mitigation:**
- Screenshot comparison tests
- Manual design review for accessibility changes
- Beta testing with accessibility user group

---

## Success Metrics

### After Sprint 1:
- [ ] `flutter analyze` shows 0 critical issues
- [ ] Text scaling works at 150% system setting
- [ ] Test suite passes with mock fixes

### After Sprint 2:
- [ ] 0 hardcoded user-facing strings in onboarding
- [ ] Error messages show in Tagalog when system is Tagalog

### After Sprint 4:
- [ ] WCAG 2.1 AA compliance (contrast, text scaling, localization)
- [ ] App bundle size reduced by ~50KB (cupertino_icons removal)
- [ ] CI passes with no new avoid_print warnings

---

## Dependency Graph

### Blockers
```
P0-4 (Remove connectivityService)
  └── Blocks: Test fixes if DI regenerates

P1-2 (Onboarding l10n)
  └── Requires: P2-3 (Typography) for text fit

P2-5 (Storage pre-check)
  └── Requires: Platform channel implementation
```

### Parallelizable
```
P1-8 (Colors) || P2-3 (Typography) || P3-3 (Theme)
  └── All UI tasks, minimal dependencies

P1-1 (Error l10n) || P1-2 (Onboarding l10n)
  └── Independent ARB key additions
```

---

## Tooling Recommendations

### Lint Configuration
```yaml
# analysis_options.yaml - Add to existing
linter:
  rules:
    avoid_print: error  # Fail CI on print
    
custom_lint:
  rules:
    - no_hardcoded_font_sizes:
        severity: error
```

### CI Checks
```yaml
# .github/workflows/ci.yml additions
- name: Analyze
  run: flutter analyze --fatal-infos

- name: Verify no CupertinoIcons
  run: |
    if grep -r "CupertinoIcons" lib test; then
      echo "Remove CupertinoIcons usage"
      exit 1
    fi

- name: Check localization coverage
  run: |
    dart run intl_translation:extract_to_arb \
      --output-dir=lib/l10n \
      lib/src/presentation/**/*.dart
    # Compare coverage
```

### Documentation Updates
```markdown
# To document after fixes:

1. CHANGELOG.md - List accessibility improvements
2. docs/UI_PATTERNS.md - Document ThemeExtension usage
3. README.md - Add accessibility compliance badge
4. CONTRIBUTING.md - Add l10n process
```

---

## Appendix: Full Finding Reference

### Module 01: Localization (12 findings)
- L10n-01: main_screen.dart:298 - 'Failed to get location'
- L10n-02: main_screen.dart:346 - 'Failed to get address'
- L10n-03: map_picker_screen.dart - Pin location strings
- L10n-04: onboarding_screen.dart - Multiple hardcoded strings
- L10n-05: reference_screen.dart:123 - 'Fare Reference Guide'
- L10n-06: reference_screen.dart:305 - 'Retry'
- L10n-07: settings_screen.dart - 6+ cache strings
- L10n-08: passenger_bottom_sheet.dart - 'Cancel', 'Apply'
- L10n-09: transport_mode_selection_modal.dart - 'Cancel'
- L10n-10: region_download_screen.dart - 8+ operations
- L10n-11: saved_routes_screen.dart - Delete dialogs
- L10n-12: travel_options_bar.dart - Sort labels

### Module 02: Typography (12 findings)
- Typo-01: fare_result_card.dart:188 - fontSize: 9 🔴 CRITICAL
- Typo-02: transport_mode_selection_modal.dart - fontSize: 10
- Typo-03: travel_options_bar.dart:120 - fontSize: 10
- Typo-04: map_picker_screen.dart - Multiple hardcoded
- Typo-05: onboarding_screen.dart:192 - fontSize: 24
- Typo-06: onboarding_screen.dart:406 - fontSize: 16
- Typo-07: onboarding_screen.dart:579 - fontSize: 12
- Typo-08: settings_screen.dart:945 - fontSize: 14
- Typo-09: All files - Missing TextScaler 🔴 CRITICAL
- Typo-10: reference_screen.dart - fontSize: 18, 12
- Typo-11: cross_region_warning_banner.dart - fontSize: 12
- Typo-12: region_download_screen.dart - 3x fontSize: 14

### Module 03: Color (10 findings)
- Color-01: map_picker_screen.dart:391 - Colors.black alpha
- Color-02: map_picker_screen.dart:496 - Colors.black alpha
- Color-03: map_picker_screen.dart:725 - Colors.black alpha
- Color-04: offline_menu_screen.dart - Colors.white variants
- Color-05: offline_menu_screen.dart - Colors.white solid
- Color-06: map_picker_screen.dart:379 - Colors.transparent
- Color-07: offline_menu_screen.dart:204 - surfaceTintColor
- Color-08: Multiple - Alpha pattern review
- Color-09: map_picker_screen.dart - Error icon colors 🟢 OK
- Color-10: map_picker_screen.dart:353 - Theme with alpha 🟢 OK

### Module 04: Accessibility (12 STRENGTHS - Preserve)
- A11y-01: fare_result_card.dart - Semantics wrapper
- A11y-02: transit_colors.dart - ThemeExtension pattern
- A11y-03: transit_colors.dart - Semantic color naming
- A11y-04: main_screen.dart - Map marker semantics
- A11y-05: app_theme.dart - Contrast ratios
- A11y-06: travel_options_bar.dart - Filter state semantics
- A11y-07: l10n/ - Localization architecture
- A11y-08: settings_screen.dart - Focus styling
- A11y-09: Motion animations - Reduced motion aware
- A11y-10: fare_result_card.dart - Graceful overflow
- A11y-11: transport_icons.dart - Semantic icons
- A11y-12: main_screen.dart - Focus order

### Modules 05-06: Theming + Map/Offline (18 findings)
- Theme-01 through Theme-07: Various theming inconsistencies
- Map-01 through Map-06: Map edge cases
- Offline-01 through Offline-04: Offline functionality issues

### Modules 07-09: Code Health (14 findings)
- Dead-01 through Dead-05: Unused code
- Test-01 through Test-05: Test code issues
- Dep-01 through Dep-03: Dependency redundancy

---

**Document Version:** 1.0.0  
**Next Review:** After Sprint 4 completion
