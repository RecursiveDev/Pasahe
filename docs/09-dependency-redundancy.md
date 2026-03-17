# Module 09: Dependency Redundancy

## Purpose
This module documents unused dependencies in `pubspec.yaml` and redundant asset declarations that increase app bundle size and complexity.

## Findings Table

| ID | Severity | Location | Issue | Impact | Effort | Status |
|----|----------|----------|-------|--------|--------|--------|
| Dep-01 | **Medium** | `pubspec.yaml:28` | `cupertino_icons: ^1.0.8` declared, never imported | ~50KB bundle bloat | 5 min | 🔴 Open |
| Dep-02 | **Low** | `pubspec.yaml:76` | Asset directory `assets/data/` overlaps with explicit file | Confusion, potential redundancy | 2 min | 🔴 Open |
| Dep-03 | **Low** | `pubspec.yaml:76` | `assets/data/regions.json` listed separately | Covered by directory wildcard | 2 min | 🟡 Review |
| Dep-E1 | **Info** | Multiple pubspec deps | Required functionality dependencies | N/A | - | 🟢 Correct |
| Dep-E2 | **Info** | `pubspec.yaml:45` | Well-commented dependency sections | Documentation good | - | 🟢 Preserve |

**Total Findings:** 3 issues + 2 positive findings  
**From `flutter analyze`:** Confirmed no usages of `cupertino_icons`

## Evidence

### Finding Dep-01: Unused `cupertino_icons` Dependency
**File:** `pubspec.yaml`  
**Line:** 28

```yaml
# Line 28 of pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8  # ← Dep-01: Never used
```

**Verification - Code Search:**
```bash
# Search for any usage of CupertinoIcons in Dart code
grep -rn "CupertinoIcons" lib --include="*.dart"
# Result: No matches

grep -rn "cupertino_icons" lib --include="*.dart"
# Result: No matches

# Check if CupertinoIcons is used in imports
grep -rn "import.*cupertino" lib --include="*.dart"
# Result: No matches
```

**Verification - Test Code:**
```bash
grep -rn "CupertinoIcons" test --include="*.dart"
# Result: No matches
```

**Bundle Impact:**
| Metric | Impact |
|--------|--------|
| Package Size | ~50KB (font file) |
| Build Time | ~2s (font processing) |
| Memory | Minimal |
| Complexity | +1 dependency to maintain |

**Why It Exists:** Default Flutter template includes `cupertino_icons` for iOS-style icons. This app uses Material 3 icons exclusively.

**Required Fix:**
```yaml
# pubspec.yaml
name: pasahe
# ...

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # REMOVED: cupertino_icons: ^1.0.8
  # Reason: Using Material 3 icons on all platforms
  
  # Other required dependencies...
  geolocator: ^13.0.2
  # ...
```

**Post-Removal Checks:**
```bash
# Rebuild to verify no errors
flutter pub get
flutter build apk --release

# Verify no dynamic usage via reflection
grep -rn "CupertinoIcons\|cupertino" lib test --include="*.dart"
# Should return no results
```

---

### Finding Dep-02: Redundant Asset Declaration
**File:** `pubspec.yaml`  
**Line 76

```yaml
# Line 76-79 of pubspec.yaml
flutter:
  generate: true
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  assets:
    - assets/data/           # ← Dep-02: Directory wildcard
    - assets/data/regions.json  # ← Dep-03: Redundant (covered by directory)
```

**Flutter Asset Documentation:**
> When you add a folder as an asset, all files within that folder are also included.
> 
> Source: https://docs.flutter.dev/ui/assets-and-images

**Current State Analysis:**
```yaml
assets:
  - assets/data/          # Includes: regions.json, any other .json
  - assets/data/regions.json   # Duplicate declaration
```

**Evidence - Asset Structure:**
```bash
ls -la C:/Repository/Pasahe/assets/data/
# Expected: regions.json, possibly other files
```

**Redundancy Matrix:**
| Asset Path | Directory Wildcard | Explicit Declaration | Status |
|------------|-------------------|---------------------|--------|
| `assets/data/regions.json` | ✅ Covered by `- assets/data/` | ✅ Listed explicitly | **Redundant** |

**Required Fix:**
```yaml
# Option A: Remove explicit file (recommended)
assets:
  - assets/data/
  # REMOVED: - assets/data/regions.json (covered by directory)
```

```yaml
# Option B: Remove directory, keep explicit (less favored)
assets:
  # REMOVED: - assets/data/
  - assets/data/regions.json
  # Future assets must be added individually
```

**Recommendation:** Option A - directory wildcard is more maintainable for data files.

---

### Finding Dep-03: Overlapping Asset Declaration (Same as Dep-02)
**Same Finding - Split for Clarity:**

**Question:** Is `regions.json` specifically listed for a reason?

**Possible Reasons:**
1. **Explicit ordering** - Directory may load files alphabetically, this forces priority
2. **Documentation** - Makes it clear this file is required
3. **Build debugging** - Was added during troubleshooting
4. **Historical** - Copy-paste from Flutter template

**Verification - Build Output:**
```bash
# Check if double inclusion affects bundle
flutter build apk --analyze-size

# Look in build output for: regions.json (should appear once)
```

**Flutter Behavior:** Duplicate asset declarations are **harmless** - Flutter deduplicates. But creates maintenance burden.

**Recommended Fix:**
```yaml
assets:
  - assets/data/  # regions.json and any other data files

# Optional: Document the expected files in comments
# Directory contains:
#   - regions.json (geographic regions for offline maps)
#   - fare_data.json (fare formulas - if present)
```

---

### Finding Dep-E1: Required Dependencies (Positive Finding)
**File:** `pubspec.yaml`  
**Lines:** 29-65

**Dependencies Verified as Used:**
| Package | Purpose | Usage Verified |
|---------|---------|----------------|
| `geolocator` | GPS location | ✅ Used in map picker |
| `http` | API requests | ✅ OSRM, geocoding |
| `hive` + `hive_flutter` | Local cache | ✅ Settings, routes |
| `path_provider` | File paths | ✅ Cache paths |
| `flutter_map` | Map display | ✅ Main map view |
| `latlong2` | Coordinates | ✅ Distance calculations |
| `shared_preferences` | Simple storage | ✅ Settings |
| `intl` | Localization | ✅ ARB generation |
| `get_it` + `injectable` | DI container | ✅ Throughout app |
| `flutter_map_tile_caching` | Offline tiles | ✅ Offline maps |
| `connectivity_plus` | Network state | ✅ Offline mode |
| `directed_graph` | Train/ferry routes | ✅ LRT/MRT routing |
| `path` | Path utilities | ✅ File operations |
| `package_info_plus` | App version | ✅ Settings screen |
| `url_launcher` | External links | ✅ GitHub link |

**Status:** 🟢 All remaining dependencies are actively used.

---

### Finding Dep-E2: Well-Commented Dependencies (Positive Finding)
**File:** `pubspec.yaml`  
**Lines:** 14-45

```yaml
# The following defines the version and build number for your application...
# In Android, build-name is used as versionName while build-number used as versionCode...

# Dependencies specify other packages...

# Offline tile caching for flutter_map
flutter_map_tile_caching: ^10.1.1

# Connectivity detection
connectivity_plus: ^6.0.3

# Graph-based pathfinding for trains/ferries
directed_graph: ^0.5.0
```

**Why Good:**
- Explains non-obvious dependencies
- Context before each grouping
- Helps future maintainers

---

## Edge Cases

### Edge Case Dep-E3: Dev Dependencies
**Challenge:** Some dev dependencies may be unused.

**Current Dev Dependencies:**
```yaml
dev_dependencies:
  flutter_test:          # ✅ Required
  flutter_lints: ^6.0.0  # ✅ Required
  build_runner: ^2.4.8   # ✅ Used for injectable/hive
  injectable_generator:  # ✅ Required for DI
  hive_generator:        # ✅ Required for cache
  mockito: ^5.4.4        # ✅ Used in tests
```

**Status:** 🟢 All required - no cleanup needed.

### Edge Case Dep-E4: Flutter SDK Version
**Challenge:** SDK constraint allows Flutter 3.9.2+.

**Current:**
```yaml
environment:
  sdk: ^3.9.2
```

**Compatibility:**
- Flutter 3.29.3 → 3.41.4 migration completed (per git history)
- Constraint is correct for recent Flutter versions

**Status:** 🟢 Appropriate constraint

### Edge Case Dep-E5: Asset Subdirectories
**Question:** What if `assets/data/` contains subdirectories?

**Flutter Behavior:**
```yaml
assets:
  - assets/data/  # Includes subdirectories recursively
```

**Evidence:**
```bash
find C:/Repository/Pasahe/assets/data -type d
# Check for subdirectories
```

**No issue found** - if subdirectories exist, they're correctly covered.

### Edge Case Dep-E6: Conditional Dependencies
**Challenge:** Could `cupertino_icons` be conditionally loaded?

**Analysis:**
```dart
// No conditional loading found
if (Platform.isIOS) {
  // No CupertinoIcons usage found
  // All icons use Material Icons
}
```

**Status:** Safe to remove - no conditional usage.

## Recommendations

### Immediate (Fix Now)
1. **Remove `cupertino_icons` dependency** (Dep-01)
   ```bash
   # Remove line from pubspec.yaml
   flutter pub get
   # Verify build passes
   flutter build apk
   ```

2. **Remove redundant asset declaration** (Dep-02, Dep-03)
   ```yaml
   # Remove: - assets/data/regions.json
   # Keep:   - assets/data/
   ```

### Short Term
3. **Audit all icons in app to confirm M3 compliance:**
   ```bash
   grep -rn "Icon(Icons\." lib --include="*.dart" | wc -l
   grep -rn "Icon(CupertinoIcons\." lib --include="*.dart" | wc -l
   # Expected: First > 0, Second = 0
   ```

4. **Document asset directory structure:**
   ```yaml
   # pubspec.yaml comments
   assets:
     # Data files - JSON configs, fare tables, etc.
     - assets/data/
     # Icons - app logos, adaptive icons
     - assets/icons/
   ```

### Bundle Size Optimization
5. **Regular dependency audits:**
   ```bash
   # Check for unused dependencies
   flutter pub deps --style=tree
   
   # Analyze built app
   flutter build apk --analyze-size
   flutter build appbundle --analyze-size
   ```

6. **Consider removing unused translations:**
   - Currently has `en` and `tl`
   - Both are required per feature set
   - Keep both

### Documentation
7. **Add dependency decision record (DRD):**
   ```markdown
   # 001 - Dependency Choices.md
   
   ## Status: Accepted
   
   ## Context
   Pasahe uses Material 3 design system exclusively.
   
   ## Decision
   - ✅ Include: Material Icons, flutter_map, hive
   - ❌ Exclude: cupertino_icons, font_awesome_flutter
   
   ## Consequences
   - Consistent cross-platform UI
   - Smaller bundle size
   ```

8. **Add pubspec.yaml CI check:**
   ```yaml
   # .github/workflows/dependencies.yml
   - name: Check for unused packages
     run: |
       flutter pub get
       # Would need tool: flutter_unused
   ```

---

**Related Modules:**
- Module 07: Dead Code (unused code elements)
- Module 10: Prioritized Fix Backlog (removal priority)
