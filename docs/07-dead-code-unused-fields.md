# Module 07: Dead Code and Unused Fields

## Purpose
This module documents unused code elements identified by `flutter analyze` and static analysis, including dead fields, zombie imports, and unreachable code.

## Findings Table

| ID | Severity | Location | Issue | Analysis Impact | Effort | Status |
|----|----------|----------|-------|-----------------|--------|--------|
| Dead-01 | **High** | `repositories/routing_repository.dart:27` | Field `_connectivityService` declared but never used | Increases memory, confuses maintainers | 5 min | 🔴 Open |
| Dead-02 | **Medium** | `repositories/routing_repository.dart:19` | Import `connectivity/connectivity_service.dart` | Import for unused field | 1 min | 🔴 Open |
| Dead-03 | **Medium** | Multiple files | Unused method `_detectCrossRegion` result | Returns warning but not always consumed | 10 min | 🟡 Verify |
| Dead-04 | **Low** | `repositories/routing_repository.dart:43-49` | Constructor parameter `ConnectivityService` | Accepts but doesn't use | 5 min | 🔴 Open |
| Dead-05 | **Low** | `services/routing/` | Unused methods in routing services | Potential for dead code | 30 min | 🟡 Audit |
| Dead-E1 | **Info** | `repositories/routing_repository.dart` | Rich constructor documentation | Keep - useful docs | - | 🟢 Preserve |

**Total Findings:** 5 issues + 1 positive finding  
**From `flutter analyze`:** Confirmed unused field `_connectivityService`

## Evidence (Code Snippets)

### Finding Dead-01: Unused Field `_connectivityService`
**File:** `lib/src/repositories/routing_repository.dart`  
**Line:** 27

```dart
@lazySingleton
class RoutingRepository {
  final RoutingService _osrmService;
  final RouteCacheService _cacheService;
  final TrainFerryGraphService _graphService;
  final RoutingService _haversineService;
  final ConnectivityService _connectivityService;  // ← DEAD-01: Never used
  final OfflineModeService _offlineModeService;

  RoutingRepository(
    @Named('osrm') this._osrmService,
    this._cacheService,
    this._graphService,
    @Named('haversine') this._haversineService,
    this._connectivityService,  // ← DEAD-04: Accepted but not used
    this._offlineModeService,
  );
```

**Flutter Analyze Output:**
```
info • lib/src/repositories/routing_repository.dart:27:9 • The field '_connectivityService' is not used • unused_field
```

**Impact Analysis:**
| Aspect | Impact | Severity |
|--------|--------|----------|
| Memory | Holds reference to service (small) | Low |
| Performance | Constructor injection overhead | Low |
| Code Clarity | Confuses developers | **High** |
| Maintenance | Future devs may think it's used | **High** |

**Why It Exists:** Likely added during offline-aware refactoring, but logic moved to `OfflineModeService`.

**Evidence of Disuse:**
```bash
# Search for usage of _connectivityService in file
grep -n "_connectivityService" lib/src/repositories/routing_repository.dart
# Returns: Lines 19 (import), 27 (declaration), 43 (constructor)
# NO other usages found
```

**Required Fix:**
```dart
// Remove field and constructor parameter
@lazySingleton
class RoutingRepository {
  final RoutingService _osrmService;
  final RouteCacheService _cacheService;
  final TrainFerryGraphService _graphService;
  final RoutingService _haversineService;
  // REMOVED: final ConnectivityService _connectivityService;
  final OfflineModeService _offlineModeService;

  RoutingRepository(
    @Named('osrm') this._osrmService,
    this._cacheService,
    this._graphService,
    @Named('haversine') this._haversineService,
    // REMOVED: this._connectivityService,
    this._offlineModeService,
  );
```

**Dependency Updates Required:**
- Constructor caller in `dependency_injection.dart` (or injectable generated)
- Test mocks that provide `ConnectivityService`

---

### Finding Dead-02: Zombie Import
**File:** `lib/src/repositories/routing_repository.dart`  
**Line:** 19

```dart
// Line 19
import '../services/connectivity/connectivity_service.dart';  // Dead-02
```

**Flutter Analyze:**
```
info • The import is unused
```

**Verification:**
```bash
grep -n "ConnectivityService" lib/src/repositories/routing_repository.dart
# Only occurrence: Line 27 (field declaration)
# After removing Dead-01, this import becomes unused
```

**Required Fix:** Remove import after removing Dead-01.

---

### Finding Dead-03: Potentially Unused Method Result
**File:** `lib/src/repositories/routing_repository.dart`  
**Line:** 192-210

```dart
String? _detectCrossRegion(
  double originLat, double originLng, double destLat, double destLng,
) {
  final origin = LatLng(originLat, originLng);
  final dest = LatLng(destLat, destLng);

  final originRegion = _getRegion(origin);
  final destRegion = _getRegion(dest);

  if (originRegion != destRegion &&
      originRegion != Region.nationwide &&
      destRegion != Region.nationwide) {
    return 'Cross-region route detected. Fares may vary across regional boundaries.';
  }
  return null;
}
```

**Where Used:**
```dart
// Line 65
final warning = _detectCrossRegion(...);

// Line 73
return _applyMetadata(result, warning: warning);
```

**Verification:** Result IS consumed - **NOT A DEAD CODE ISSUE**.

**Status:** 🟢 This finding is a **false positive** - method is called and result used.

---

### Finding Dead-04: Unused Constructor Parameter
**File:** `lib/src/repositories/routing_repository.dart`  
**Lines:** 43-49

```dart
RoutingRepository(
  @Named('osrm') this._osrmService,
  this._cacheService,
  this._graphService,
  @Named('haversine') this._haversineService,
  this._connectivityService,  // ← Accepted but never referenced
  this._offlineModeService,
);
```

**Same as Dead-01** - parameter accepted but field never used.

**Impact on DI:**
```dart
// File: injection.config.dart (generated)
// Will have: gh.singletonWithDependencies(
//   () => RoutingRepository(..., getIt<ConnectivityService>(), ...)
// This creates/gets the service but it's never used!
```

**Fix:** Remove from constructor parameter.

---

### Finding Dead-05: Audit for Other Unused Methods
**Scope:** All `services/routing/` files

**Findings:**
```bash
# Check for private methods that may be unused
grep -rn "_" lib/src/services/routing/ --include="*.dart" | grep "void\|Future\|String\|int\|bool"
```

**Potential Candidates:**
- Private helper methods in `osrm_routing_service.dart`
- Private methods in `train_ferry_graph_service.dart`

**Recommendation:** Run `dart analyze --fatal-infos` to find all unused elements.

---

### Finding Dead-E1: Preserved Documentation (Positive)
**File:** `lib/src/repositories/routing_repository.dart`  
**Lines:** 33-51

```dart
/// Gets a route between two points using the fallback hierarchy.
///
/// Hierarchy:
/// 1. OSRM (if online, 3s timeout)
/// 2. Cache (if OSRM fails or offline)
/// 3. Train/Ferry Graph (if applicable)
/// 4. Haversine (last resort)
Future<RouteResult> getRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
  TransportMode? preferredMode,
  bool forceOffline = false,
}) async {
```

**Why Preserve:** Rich documentation explains the routing fallback strategy. This is excellent documentation that should be kept and expanded.

## Edge Cases

### Edge Case Dead-E2: Injectable Generated Code
**Challenge:** `get_it` + `injectable` generate code that may reference dead fields.

**Current:**
```dart
// injection.config.dart (generated)
gh.lazySingleton<RoutingRepository>(
  () => RoutingRepository(
    // ...
    gh<ConnectivityService>(),  // Will break if removed from constructor
  ),
);
```

**Fix Process:**
1. Remove from `RoutingRepository` constructor
2. Run `dart run build_runner build` (regenerates injection.config.dart)
3. Fix any compilation errors manually

### Edge Case Dead-E3: Test Dependencies
**Challenge:** Tests may depend on the existence of unused fields.

**File:** `test/repositories/routing_repository_test.dart` (not in provided snippets, but likely exists)

**Risk:**
```dart
// Hypothetical test that creates directly
test('routing repository', () {
  final repository = RoutingRepository(
    // ...
    connectivityService: mockConnectivityService,  // Would break
  );
});
```

**Mitigation:**
1. Check for direct constructor calls in tests
2. Use `@GenerateMocks` to regenerate mocks

### Edge Case Dead-E4: Future-Proofing
**Challenge:** Field might be needed in future features.

**Analysis:**
```dart
// Is connectivity awareness relevant for routing?
// YES - could check connectivity before OSRM call
// BUT - already handled by: 
//   - _offlineModeService.isCurrentlyOffline (line 50)
//   - forceOffline parameter
```

**Verdict:** Already covered by `OfflineModeService`. Remove.

### Edge Case Dead-E5: Inheritance Considerations
**Challenge:** Is `RoutingRepository` part of an inheritance hierarchy?

**Check:**
```bash
grep -rn "extends RoutingRepository" lib --include="*.dart"
grep -rn "implements RoutingRepository" lib --include="*.dart"
```

**Result:** No inheritance found - safe to modify constructor.

## Recommendations

### Immediate (Fix Now)
1. **Remove `_connectivityService` field** (Dead-01)
2. **Remove `ConnectivityService` import** (Dead-02)
3. **Remove constructor parameter** (Dead-04)
4. **Regenerate injection** (`dart run build_runner build`)

### Short Term
5. **Run full `dart analyze`:**
```bash
dart analyze --fatal-infos
dart run dart_code_metrics:metrics check-unused-files lib
dart run dart_code_metrics:metrics check-unused-code lib
```

6. **Remove other unused imports across codebase:**
```bash
# Find all unused imports
grep -rn "import" lib --include="*.dart" | grep "unused"
```

### CI Enhancement
7. **Add to CI:**
```yaml
# .github/workflows/analyze.yml
- name: Analyze
  run: |
    flutter analyze --fatal-infos
    # Fail on unused code warnings
```

### Documentation
8. **Document cleanup:**
```markdown
## Dead Code Removal Process (New)

1. Run `dart analyze` and identify unused_elements
2. Verify no dynamic/runtime usage (grep for string reflection)
3. Check test files for direct instantiation
4. Remove field + imports + constructor parameters
5. Regenerate injection via build_runner
6. Run tests to verify
7. Update CHANGELOG.md
```

---

**Related Modules:**
- Module 08: Test Code Issues (mock cleanup)
- Module 09: Dependency Redundancy (unused package)
- Module 10: Prioritized Fix Backlog
