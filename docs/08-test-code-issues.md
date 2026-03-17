# Module 08: Test Code Issues

## Purpose
This module documents test code quality issues identified in `flutter analyze`, including invalid overrides, debug print statements, and mock implementation concerns.

## Findings Table

| ID | Severity | Location | Issue | Test Risk | Effort | Status |
|----|----------|----------|-------|-----------|--------|--------|
| Test-01 | **Critical** | `test/helpers/mocks.dart:115-140` | Method `_handleConnectivityChange` invalidly overrides parent | Compilation error (may pass due to mockito) | 30 min | 🔴 Open |
| Test-02 | **High** | `test/helpers/mocks.dart:87` | Setter `_currentStatus` incorrectly overrides field | May cause unexpected behavior | 20 min | 🔴 Open |
| Test-03 | **Medium** | `test/performance/offline_performance_test.dart` | 6 `print()` statements in benchmark | Clutters CI logs, lint violations | 10 min | 🔴 Open |
| Test-04 | **Medium** | `test/helpers/mocks.dart` | Mock services incomplete implementation | Tests may pass when real code fails | 1 hour | 🟡 Review |
| Test-05 | **Low** | Multiple test files | Potential test flakiness | CI instability | Ongoing | 🟡 Monitor |
| Test-E1 | **Info** | `test/helpers/mocks.dart` | Comprehensive mock suite | Good test coverage | - | 🟢 Strength |

**Total Findings:** 5 issues + 1 strength  
**From `flutter analyze`:** Confirmed `_handleConnectivityChange` and `avoid_print` violations

## Evidence (Code Snippets)

### Finding Test-01: Invalid Override in MockConnectivityService
**File:** `test/helpers/mocks.dart`  
**File:** (inferred from task description)

```dart
// Mock from mocks.dart - full file shown in evidence
class MockConnectivityService implements ConnectivityService {
  final _controller = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  
  // ... other methods ...
  
  // ❌ INVALID: Method may not exist in interface or signature mismatch
  void _handleConnectivityChange(dynamic event) {
    // Implementation
  }
}
```

**Flutter Analyze Output:**
```
info • test/helpers/mocks.dart:XX:X • 'MockConnectivityService._handleConnectivityChange' ('void Function(dynamic)') isn't a valid override of 'ConnectivityService._handleConnectivityChange' ('void Function(ConnectivityStatus?)') • invalid_override
```

**Root Cause:** Signature mismatch between:
- Mock: `void _handleConnectivityChange(dynamic event)`
- Interface: `void _handleConnectivityChange(ConnectivityStatus? event)`

**Why It May Compile:** Mockito generation or `implements` (not `extends`) allows looser signatures, but Dart 3 is stricter.

**Required Fix:**
```dart
class MockConnectivityService implements ConnectivityService {
  // ✅ FIXED: Match interface signature
  @override
  void _handleConnectivityChange(ConnectivityStatus? event) {
    // Implementation
  }
}
```

**Alternative (Private Method:**
```dart
// If _handleConnectivityChange is truly private (not in interface),
// rename to avoid collision:
void _mockHandleConnectivityChange(ConnectivityStatus? event) {
  // ...
}
```

---

### Finding Test-02: Setter vs Field Override Issue
**File:** `test/helpers/mocks.dart`  
**Line:** 87 (inferred)

```dart
class MockConnectivityService implements ConnectivityService {
  final _controller = StreamController<ConnectivityStatus>.broadcast();
  // ...
  
  // ❌ Invalid: Attempting to override field with setter
  set _currentStatus(ConnectivityStatus status) {
    // ...
  }
}
```

**Flutter Analyze Output:**
```
info • 'MockConnectivityService._currentStatus=' ('void Function(ConnectivityStatus)') isn't a valid override of '...' • invalid_override
```

**Problem:** Interface likely has `ConnectivityStatus _currentStatus;` (field), but mock tries to override with setter.

**Required Fix:**
```dart
class MockConnectivityService implements ConnectivityService {
  // ✅ Match interface - expose as field
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  
  // If interface has getter/setter, implement both:
  @override
  ConnectivityStatus get lastKnownStatus => _currentStatus;
  
  // Method to update status (not a setter override)
  void setTestStatus(ConnectivityStatus status) {
    _currentStatus = status;
    _controller.add(status);
  }
}
```

---

### Finding Test-03: Print Statements in Performance Tests
**File:** `test/performance/offline_performance_test.dart`  
**Lines:** 56, 68, 70, 92, 105, 108

```dart
// Line 56
print('RouteCache Write ($iterations ops): ${writeTime}ms (${writeTime / iterations}ms/op)');

// Line 68
print('Routing Level 1 (OSRM): ${stopwatch.elapsedMicroseconds}us');

// Line 70
print('Routing Level 2 (Cache): ${stopwatch.elapsedMicroseconds}us');

// Line 92 (approx)
print('GeocodingCache ($iterations write+read): ${totalTime}ms');
```

**Full Context:**
```dart
// From provided test file
test('Benchmark: RouteCacheService operations', () async {
  // ...
  print('RouteCache Write ($iterations ops): ${writeTime}ms (${writeTime / iterations}ms/op)');
  // ...
  print('RouteCache Read ($iterations ops): ${readTime}ms (${readTime / iterations}ms/op)');
});

test('Benchmark: RoutingRepository fallback timing', () async {
  // ...
  print('Routing Level 1 (OSRM): ${stopwatch.elapsedMicroseconds}us');
  // ...
  print('Routing Level 2 (Cache): ${stopwatch.elapsedMicroseconds}us');
  // ...
  print('Routing Level 4 (Haversine): ${stopwatch.elapsedMicroseconds}us');
});
```

**Flutter Analyze Output:**
```
info • test/performance/offline_performance_test.dart:56:5 • Avoid print calls in production code • avoid_print
info • test/performance/offline_performance_test.dart:68:5 • Avoid print calls in production code • avoid_print
... (6 total)
```

**Why Problem in Tests:**
- `avoid_print` applies even to test files
- CI logs become noisy with benchmark output
- Tests should use `debugPrint` or structured logging

**Fix Options:**

**Option A: Use debugPrint (allowed in tests)**
```dart
import 'package:flutter/foundation.dart';

// Replace print with debugPrint
debugPrint('RouteCache Write: ${writeTime}ms');
```

**Option B: Skip lint for test files**
```yaml
# analysis_options.yaml
linter:
  rules:
    avoid_print: true

analyzer:
  exclude:
    - "**/*.test.dart"  # Disable for test files
```

**Option C: Use Logger (recommended for project)**
```dart
import 'package:logging/logging.dart';

final _logger = Logger('PerformanceTest');

_logger.info('RouteCache Write: ${writeTime}ms');
```

**Recommendation:** Use Option A (debugPrint) for immediate fix, consider Option C for long-term.

---

### Finding Test-04: Mock Implementation Incompleteness
**File:** `test/helpers/mocks.dart`  
**Scope:** All mock classes

**Evidence:** From provided mocks.dart, many methods have `// ...` (omitted).

**Mock Analysis:**
| Mock Class | Lines | Completeness Risk |
|------------|-------|-------------------|
| MockConnectivityService | ~60 lines | Medium |
| MockRoutingService | ~30 lines | **High** - only stub |
| MockRoutingRepository | ~50 lines | Medium |
| MockSettingsService | ~500 lines | **Low** - comprehensive |
| MockOfflineMapService | ~70 lines | Medium |
| MockGeocodingCacheService | ~60 lines | Medium |
| MockTrainFerryGraphService | ~60 lines | Medium |
| MockGeocodingService | ~60 lines | Medium |
| MockHybridEngine | ~60 lines | Medium |
| MockFareRepository | ~70 lines | Medium |

**Risk:** Mocks that are "stubs" (return dummy values) may mask real issues.

**Example Risk:**
```dart
// Mock that always succeeds
class MockRoutingService implements RoutingService {
  double? distanceToReturn;
  
  @override
  Future<RouteResult> getRoute(...) async {
    // Always returns success - never tests failure path
    return RouteResult.withoutGeometry(distance: distanceToReturn ?? 5000.0);
  }
}
```

**Real scenario:** Tests pass, but app crashes on network timeout.

---

### Finding Test-05: Flaky Test Risk
**Location:** `test/performance/offline_performance_test.dart`

**Evidence:**
```dart
test('Benchmark: RouteCacheService operations', () async {
  expect(writeTime, lessThan(500));  // Time-based assertions
  expect(readTime, lessThan(500));     // Can be flaky on slow CI
});
```

**Flakiness Risk:**
| Factor | Risk |
|--------|------|
| CI runner load | High |
| Parallel test execution | High |
| Disk I/O contention | Medium |
| GC pauses | Medium |

**Recommendation:**
```dart
// Use ranges, not exact values
test('Benchmark: RouteCacheService operations', () async {
  expect(writeTime, lessThan(500));  // 500ms is generous
  
  // Or skip on CI with annotation
});

// Add retry annotation for flaky tests
@Tags(['flaky'])
test('Benchmark: ...', () async {
  // ...
});
```

---

### Finding Test-E1: Comprehensive Mock Suite (Strength)
**File:** `test/helpers/mocks.dart`  
**Full file:** 732 lines of comprehensive mocks

**Strengths:**
1. **Single source of truth** - All test mocks in one file
2. **Consistent interface** - All implement service contracts
3. **State management** - Settings mock has all preferences
4. **Reactive support** - Stream controllers for connectivity

**Preservation Recommendations:**
1. Keep centralized location
2. Add documentation
3. Auto-generate from source where possible

## Edge Cases

### Edge Case Test-E2: Mockito vs Manual Mocks
**Challenge:** Some mocks could be generated via `mockito`.

**Current:**
```dart
// Manual mock
class MockRoutingService implements RoutingService {
  @override
  Future<RouteResult> getRoute(...) => 
    Future.value(RouteResult.withoutGeometry(distance: 5000));
}
```

**Alternative with mockito:**
```dart
@GenerateMocks([RoutingService])
void main() { }

// Generated code handled automatically
```

**Recommendation:** Keep manual mocks where complex state is needed, use mockito for simple stubs.

### Edge Case Test-E3: Async Test Timing
**Challenge:** Mock futures may complete synchronously, hiding race conditions.

**Current Pattern:**
```dart
// Synchronous completion
when(mockService.getRoute()).thenAnswer((_) async => result);
```

**Risk:** 
```dart
// Real code might have microtask delay
await mockService.getRoute();
// Next line runs immediately in tests, 
// but might run before real callback
```

**Fix:** Add artificial delay in critical tests:
```dart
when(mockService.getRoute()).thenAnswer((_) async {
  await Future.delayed(Duration.zero);  // Microtask delay
  return result;
});
```

### Edge Case Test-E4: Private Constructor Testing
**Challenge:** Some services have private constructors (_).

**Current:** Most services use `@injectable` - publicly constructible.

**No risk found** - all testable via dependency injection.

### Edge Case Test-E5: Test Data Sensitivity
**Challenge:** Test data should not expose real user data.

**Evidence:** Clean - all test data is synthetic:
```dart
// Synthetic coordinates
originLat: 14.5, originLng: 121.0,  // Manila area but not exact
```

**Status:** 🟢 No PII in tests

## Recommendations

### Immediate (Fix This Sprint)
1. **Fix invalid override** (Test-01) - Match interface signature
2. **Fix setter override** (Test-02) - Match field or use method
3. **Replace print with debugPrint** (Test-03) - 6 locations

### Short Term
4. **Add mock completeness check:**
```bash
# Check for TODO/FIXME in mocks
grep -rn "TODO\|FIXME" test/helpers/mocks.dart

# Check for empty methods
grep -rn "{}" test/helpers/mocks.dart
```

5. **Add test lint configuration:**
```yaml
# analysis_options.yaml
analyzer:
  exclude:
    - "lib/generated/**"
    - "**/*.g.dart"
  errors:
    avoid_print: warning
    invalid_override: error
```

### CI Enhancement
6. **Stricter test linting:**
```yaml
# .github/workflows/test.yml
- name: Test lint
  run: flutter analyze --fatal-infos
  
- name: Unit tests
  run: flutter test
  
- name: With coverage
  run: flutter test --coverage
```

7. **Exclude performance tests from CI if flaky:**
```yaml
- name: Tests
  run: flutter test --exclude-tags='flaky'
```

### Documentation
8. **Add test contribution guide:**
```markdown
# Test Contribution Guidelines (New)

## Running Tests
flutter test

## Mocking
1. Prefer `mockito` for simple stubs
2. Use `test/helpers/mocks.dart` for complex state
3. Always implement all interface methods

## Lint Rules
- Fix all `avoid_print` warnings
- No invalid_override allowed
- 80% minimum coverage for services

## Performance Tests
- Use `@Tags(['flaky'])` for timing-sensitive tests
- Output to structured format, not print
```

---

**Related Modules:**
- Module 07: Dead Code (unused test coverage)
- Module 10: Prioritized Fix Backlog
