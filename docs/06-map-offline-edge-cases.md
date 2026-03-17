# Module 06: Map and Offline Edge Cases

## Purpose
This module documents UI/UX considerations specific to map interactions, offline functionality, and edge cases that occur in low-connectivity scenarios or during map operations.

## Findings Table

| ID | Severity | Location | Issue | Edge Case | Effort | Status |
|----|----------|----------|-------|-----------|--------|--------|
| Map-01 | **High** | `screens/map_picker_screen.dart` | Rate limiting UI feedback | 429 errors from Nominatim show generic error | 2 hours | 🔴 Open |
| Map-02 | **High** | `screens/region_download_screen.dart` | Large region downloads > 500MB | Memory pressure, storage failure | 4 hours | 🔴 Open |
| Map-03 | **Medium** | `screens/map_picker_screen.dart` | Pin placement without reverse geocode | User taps, sees coordinates instead of address | 1 hour | 🔴 Open |
| Map-04 | **Medium** | `screens/main_screen.dart` | OSRM timeout fallback | >3s shows no feedback before haversine fallback | 2 hours | 🔴 Open |
| Map-05 | **Medium** | `screens/offline_menu_screen.dart` | Offline mode disabled tiles | No visual indication which regions are cached | 3 hours | 🔴 Open |
| Map-06 | **Medium** | Repository layer | Cross-region route detection | Manila->Cebu shows warning but no fare adjustment | 1 hour | 🟡 Design |
| Offline-01 | **High** | `screens/region_download_screen.dart` | Storage full during download | No pre-check, opaque error | 2 hours | 🔴 Open |
| Offline-02 | **High** | `test/helpers/mocks.dart` | Mock connectivity service | Tests may fake connectivity but real network state differs | N/A | 🔴 Test Fix |
| Offline-03 | **Medium** | `screens/main_screen.dart` | Cached route expiry | Routes expire without user knowledge | 1 hour | 🟡 Document |
| Offline-04 | **Low** | `screens/map_picker_screen.dart` | Cached geocode stale data | Old address shown if location redeveloped | 4 hours | 🟢 Acceptable |
| Offline-E1 | **Info** | `services/offline/` | Offline-first architecture | Good pattern - preserve | - | 🟢 Strength |
| Offline-E2 | **Info** | `services/routing/route_cache_service.dart` | TTL-based cache | Expired routes gracefully fall back | - | 🟢 Good Pattern |

**Total Findings:** 10 issues + 2 strengths  
**Offline Strategy:** Tiered fallback (OSRM → Cache → Graph → Haversine)

## Evidence (Code Snippets)

### Finding Map-01: Rate Limiting UI Feedback
**Context:** Nominatim API rate limit (1 req/sec) exceeded shows generic error.

**Current Error Handling:**
```dart
// Current: Generic error for all failures
try {
  final result = await _geocodingService.reverseGeocode(lat, lng);
} catch (e) {
  // Shows: "Failed to get address" (see L10n-02)
  setState(() => _errorMessage = 'Failed to get address');
}
```

**Recent Fix:** Partial fix added (lines 95-100 from git history):
```dart
// Line ~95 in recent commit
// "increase map picker reverse-geocode debounce from 400ms to 1100ms"
// Added RateLimitFailure to failures.dart
```

**Remaining Issue:** UI doesn't communicate "Please wait before searching again" - just shows generic error.

**Required UX:**
```dart
if (error is RateLimitFailure) {
  return SnackBar(
    content: Text('Rate limit reached. Please wait ${error.retryAfter}s.'),
    duration: Duration(seconds: error.retryAfter),
  );
}
```

---

### Finding Map-02: Large Region Download Size
**File:** `lib/src/presentation/screens/region_download_screen.dart`  
**Context:** Map tile regions can exceed 500MB.

**Current Download UI:**
```dart
// Line ~95 (inferred)
content: Text('${progress.region.name} downloaded successfully!'),
```

**Risk Scenarios:**
| Scenario | User Impact | Current Handling |
|----------|-------------|----------------|
| Download > 500MB | Storage full | Generic error |
| Slow connection | Timeout | Retry dialog |
| Background kill | Corrupted tiles | Partial cleanup |
| Network interruption | Partial download | Retry available |

**Evidence (from lib/src/presentation/screens/region_download_screen.dart:106):**
```dart
// Error handling
catch (e) {
  content: Text('Download failed: ${progress.errorMessage}'),
}
```

**Gap:** No pre-download size check or storage availability validation.

---

### Finding Map-03: Pin Placement Without Geocode Result
**File:** `lib/src/presentation/screens/map_picker_screen.dart`

```dart
// Current flow
onMapTap: (position) async {
  setState(() => _selectedLocation = position);
  
  try {
    final address = await _geocodingService.reverseGeocode(
      position.latitude, 
      position.longitude,
    );
    setState(() => _address = address);
  } catch (e) {
    // Shows coordinates instead of address
    setState(() => _address = '${position.latitude}, ${position.longitude}');
  }
}
```

**Edge Case:** Rural areas or remote islands may have no Nominatim data.

**Current UX:** Users see GPS coordinates (unfriendly) instead of meaningful address.

**Recommendation:**
```dart
if (address == null) {
  return 'Location selected (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
}
```

---

### Finding Map-04: OSRM Timeout Fallback Feedback
**File:** `lib/src/repositories/routing_repository.dart`  
**Lines:** 63-77

```dart
// Level 1: OSRM (Online Road Routing)
try {
  debugPrint('RoutingRepository: Trying OSRM...');
  final result = await _osrmService
      .getRoute(originLat, originLng, destLat, destLng)
      .timeout(const Duration(seconds: 3));  // 3-second timeout
  // ...
} catch (e) {
  debugPrint('RoutingRepository: OSRM failed or timed out: $e');
}

// Level 4: Haversine (Last resort)
debugPrint('RoutingRepository: Falling back to Haversine');
```

**User Impact:**
1. User taps "Calculate"
2. OSRM times out silently
3. Falls back to Haversine (less accurate)
4. User sees result but doesn't know it used fallback

**Edge Cases:**
- User expects precise distance, gets straight-line approximation
- Fare calculation based on wrong distance
- No visual indicator of accuracy degradation

**Recommended UX:**
```dart
// Add accuracy badge (already exists in fare_result_card.dart - A11y-01)
// BUT add explicit fallback warning:
if (routeResult.source == RouteSource.haversine) {
  return CrossRegionWarningBanner(
    message: 'Using approximate distance. Connect to internet for precise fare.',
  );
}
```

---

### Finding Map-05: Offline Mode Disabled Tiles Visual
**File:** `lib/src/presentation/screens/offline_menu_screen.dart`  
**File:** `lib/src/presentation/screens/map_picker_screen.dart`

**Current State:**
```dart
// In map_picker_screen.dart
// When offline and no cached tile:
// Shows blank/gray background (OSM default)
```

**Edge Case:** User in offline mode taps region not downloaded - sees broken map.

**Desired UX:** Visual indication of available vs unavailable tiles.

---

### Finding Map-06: Cross-Region Route Warning
**File:** `lib/src/repositories/routing_repository.dart`  
**Lines:** 192-210

```dart
String? _detectCrossRegion(
  double originLat, originLng, destLat, destLng,
) {
  final originRegion = _getRegion(LatLng(originLat, originLng));
  final destRegion = _getRegion(LatLng(destLat, destLng));
  
  if (originRegion != destRegion &&
      originRegion != Region.nationwide &&
      destRegion != Region.nationwide) {
    return 'Cross-region route detected. Fares may vary across regional boundaries.';
  }
  return null;
}
```

**Evidence:** Warning is displayed (see Module 01 for hardcoded string).

**Edge Case Questions:**
- Does fare calculation use different provincial rate sets? (Provincial mode toggle)
- Is this just informational, or does it affect calculation?
- Manila → Cebu flight (not vehicle) - does warning make sense?

**Current Behavior:** Warning shown, but fare uses standard calculation.

---

### Finding Offline-01: Storage Full During Download
**File:** `lib/src/presentation/screens/region_download_screen.dart`

**Current Flow:**
```dart
// Line 106
content: Text('Download failed: ${progress.errorMessage}'),
```

**Missing Pre-Check:**
```dart
// Required validation (not present)
final availableSpace = await _offlineMapService.getAvailableSpace();
final requiredSpace = region.estimatedSize;

if (availableSpace < requiredSpace) {
  return AlertDialog(
    title: Text('Insufficient Storage'),
    content: Text('This region requires ${formatBytes(requiredSpace)}. '
                  'You have ${formatBytes(availableSpace)} available.'),
  );
}
```

---

### Finding Offline-02: Mock Connectivity Service Risk
**File:** `lib/src/test/helpers/mocks.dart`  

**Context:** Test mocks simulate connectivity.

**Risk:** Tests pass with mocked connectivity, but real phone may have:
- Airplane mode with WiFi (connectivity_plus reports "none" but WiFi works)
- Captive portal (reports "wifi" but no actual internet)
- Metered connection (reports "4g" but expensive)

**Evidence from mocks.dart:**
```dart
class MockConnectivityService implements ConnectivityService {
  Future<bool> isServiceReachable(String url) async {
    return true;  // Always reachable in tests
  }
}
```

**Test Gap:** No tests for actual connectivity failure scenarios.

---

### Finding Offline-03: Cached Route Expiry
**File:** `lib/src/services/routing/route_cache_service.dart`

**Evidence:** Caching with TTL:
```dart
// TTL-based expiration (from repository pattern)
class CachedRoute {
  final DateTime cachedAt;
  final DateTime expiresAt;  // TTL-based
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

**Edge Case:** User plans trip, caches route, returns next day - route expired silently.

**Current UX:** No "your cached routes" management UI found.

---

### Finding Offline-04: Stale Geocache Data
**File:** `lib/src/services/geocoding/geocoding_cache_service.dart`

**Risk:** Location is redeveloped (new building, renamed street), but cache shows old address.

**Mitigation:** TTL on geocoding cache (implied but not verified).

**Acceptance:** Low risk for fare estimation use case - coordinates are accurate, address is informational.

---

### Finding Offline-E1: Offline-First Architecture (Strength)
**Location:** `lib/src/services/offline/`

**Pattern:**
- `OfflineMapService` - Tile caching
- `OfflineModeService` - Global offline state
- `GeocodingCacheService` - Address caching
- `RouteCacheService` - Route caching

**Why Good:**
- Every online operation has offline fallback
- Graceful degradation (OSRM → Cache → Haversine)
- User can manually download regions for guaranteed offline

**Preservation:** Document as "Pasahe offline-first pattern"

---

### Finding Offline-E2: TTL-Based Route Cache (Good Pattern)
**File:** `lib/src/services/routing/route_cache_service.dart`

```dart
// Good pattern - expires old routes
class CachedRoute {
  final RouteResult result;
  final DateTime cachedAt;
  final DateTime expiresAt;  // e.g., 7 days TTL
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

**Benefit:** Prevents stale pricing from old fare formulas.

## Edge Cases

### Edge Case Map-E3: Low-Battery Mode
**Scenario:** Android Low Battery Mode or iOS Low Power Mode disables:
- Background fetch
- Network operations
- Location updates

**Current Behavior:** App may not detect these restrictions.

**Mitigation:** Document known limitation.

### Edge Case Map-E4: VPN / Proxy
**Scenario:** User on corporate VPN or HTTP proxy.

**Risk:**
- OSRM/geocoding may block proxy IPs
- Rate limits shared across VPN users
- SSL certificate issues

**Evidence:** No proxy configuration found in HTTP clients.

### Edge Case Map-E5: Location Accuracy
**Scenario:** GPS reports accuracy > 100 meters (indoor, dense urban).

**Current:** Uses raw coordinates without accuracy check.

**Risk:** Manila CBD canyons cause 200m+ GPS error - wrong barangay selected.

**Recommendation:**
```dart
if (location.accuracy > 100) {
  return WarningBanner(
    message: 'GPS accuracy is ${location.accuracy.round()}m. Pin location manually for best results.',
  );
}
```

### Edge Case Offline-E6: Region Metadata Sync
**Scenario:** New LRT lines added, fare formulas updated.

**Current:** Bundled data in app assets - requires app update.

**Gap:** No runtime sync mechanism for fare formula updates.

## Recommendations

### High Priority (Fix in This Sprint)
1. **Add storage pre-check** (Offline-01) - Prevent failed downloads
2. **Show download size estimate** (Map-02) - User informed consent
3. **Rate limit specific error** (Map-01) - Better UX for 429 errors

### Medium Priority (Next Sprint)
4. **Add fallback accuracy badge** (Map-04) - Visual indication of route accuracy
5. **Manual coordinate UX** (Map-03) - Better rural area experience
6. **Offline mode tile visualization** (Map-05) - Show cached vs unavailable

### Documentation (Maintenance)
7. **Document cross-region behavior** (Map-06) - Clarify informational vs actionable
8. **Add offline-first pattern docs** - Reference implementation for other Flutter apps
9. **Known limitations statement** - Low-battery, VPN, stale data

### Code Patterns to Preserve
10. **Offline-first architecture** (Offline-E1) - Template for other features
11. **TTL-based caching** (Offline-E2) - Prevents stale data

### Testing Recommendations
12. **Add offline integration tests:**
- Download → Airplane mode → Use cached tiles
- OSRM timeout → Fallback to haversine
- Storage full scenario

---

**Related Modules:**
- Module 10: Prioritized Fix Backlog (ranking)
- Module 08: Test Code Issues (mock coverage)
