# Module 11: Navigation, Error, and Feedback Patterns

## Purpose
This module documents navigation patterns, error/loading/empty states, retry mechanisms, rate limit UX, permission handling, and haptic feedback patterns in the Pasahe app. These patterns ensure consistent user experience across all screens and states.

**Related:** [00-uiux-should-include-exclude](./00-uiux-should-include-exclude.md) | [06-map-offline-edge-cases](./06-map-offline-edge-cases.md) | [01-localization-issues](./01-localization-issues.md)

---

## Summary Table

| Category | Patterns | Coverage | Status |
|----------|----------|----------|--------|
| Navigation | 4 | ✅ Strong | 🟢 Good |
| Error States | 5 | ⚠️ Partial | 🟡 Needs Work |
| Loading States | 4 | ✅ Strong | 🟢 Good |
| Empty States | 2 | ⚠️ Partial | 🟡 Needs Work |
| Retry Patterns | 3 | ⚠️ Partial | 🟡 Needs Work |
| Rate Limit UX | 2 | ❌ Missing | 🔴 Not Implemented |
| Permission UX | 3 | ⚠️ Backend Only | 🟡 Needs UI |
| Haptics/Feedback | 1 | ❌ Missing | 🔴 Not Implemented |

---

## Findings Table

| ID | Severity | Category | Location | Issue | Status |
|----|----------|----------|----------|-------|--------|
| Nav-01 | **High** | Navigation | `map_picker_screen.dart:216` | Result return via `Navigator.pop()` lacks error channel | 🟡 Partial |
| Nav-02 | Medium | Navigation | `main_screen.dart:313` | No result validation after navigation | 🟢 Acceptable |
| Nav-03 | **High** | Navigation | `region_download_screen.dart` | Retry exists but inconsistent across errors | 🟡 Partial |
| Nav-04 | Medium | Navigation | `passenger_bottom_sheet.dart:27` | Modal dismissible without explicit cancel | 🟢 By Design |
| Nav-05 | Low | Navigation | Multiple | Back gesture not always handled for modals | 🟡 Android Only |
| Err-01 | **High** | Error | `main_screen.dart:296` | Generic error messages not actionable | 🔴 Open |
| Err-02 | **High** | Error | `geocoding_service.dart:303` | Permission failures use exceptions, not typed results | 🟡 Patterns Exist |
| Err-03 | Medium | Error | Multiple | Error messages hardcoded, not localized | 🔴 See L10n-02 |
| Err-04 | Medium | Error | `map_picker_screen.dart` | Silent failures on address lookup | 🔴 Open |
| Err-05 | Low | Error | `reference_screen.dart:305` | Retry button present but limited scope | 🟢 Good Pattern |
| Load-01 | Info | Loading | `map_picker_screen.dart:46-47` | Dual loading states (search + address) | 🟢 Good Pattern |
| Load-02 | Info | Loading | `map_picker_screen.dart:792` | AnimatedSwitcher for loading transitions | 🟢 Good Pattern |
| Load-03 | Medium | Loading | `region_download_screen.dart:329` | Binary loading for large downloads | 🟡 Needs Progress |
| Load-04 | Low | Loading | `reference_screen.dart:330` | Center progress lacks context | 🟡 Enhance |
| Empty-01 | Medium | Empty | `saved_routes_screen.dart` | Empty list handling minimal | 🟡 Enhance |
| Empty-02 | Medium | Empty | Search results | No "no results" UX pattern defined | 🔴 Missing |
| Retry-01 | Info | Retry | `geocoding_service.dart:47` | Throttle with delay implemented | 🟢 Backend Pattern |
| Retry-02 | Medium | Retry | `region_download_screen.dart:360` | UI retry for download failures | 🟢 Good Pattern |
| Retry-03 | **High** | Retry | Network failures | No user-initiated retry in main flow | 🔴 Missing |
| Rate-01 | **High** | Rate Limit | `geocoding_service.dart:47` | Throttle exists but no UX feedback | 🔴 Critical Gap |
| Rate-02 | Medium | Rate Limit | API calls | No countdown or cooldown indicator | 🔴 Missing |
| Perm-01 | Info | Permission | `geocoding_service.dart:282` | Permission check with specific failures | 🟢 Backend Pattern |
| Perm-02 | **High** | Permission | `failures.dart:31` | Failure types exist but UI not implemented | 🔴 Missing |
| Perm-03 | Medium | Permission | Location access | No settings deep-link for denied-forever | 🔴 Missing |
| Haptic-01 | Low | Feedback | Across app | No haptic patterns implemented | 🔴 Missing |
| Haptic-02 | Low | Feedback | Counter buttons | Missing tactile feedback on increment | 🔴 Missing |

**Total Findings:** 23 (11 ✅ Good, 8 🔴 Missing, 4 🟡 Partial)

---

## Evidence (Code Snippets)

### Finding Nav-01: Navigation Result Without Error Channel

**File:** `lib/src/presentation/screens/map_picker_screen.dart:216`

```dart
// Lines 216-217: Success case returns location
Navigator.pop(context, _selectedLocation);

// Lines 399: Cancel returns null
onPressed: () => Navigator.pop(context),
```

**Issue:** Error cases during reverse geocoding don't communicate failure reason to caller.

**Current Implementation:**
```dart
// main_screen.dart:313 - Receiving code
final LatLng? selectedLatLng = await Navigator.push<LatLng>(
  context,
  MaterialPageRoute(
    builder: (context) => MapPickerScreen(/* ... */),
  ),
);
// Null check only - no error context
if (selectedLatLng != null) {
  await _processMapPickerResult(selectedLatLng, isOrigin);
}
```

**Edge Case:** User selects location → reverse geocode fails → user returns to previous screen with no feedback.

**Recommendation:**
```dart
// Return a result object instead of nullable
class MapPickerResult {
  final LatLng? location;
  final String? errorMessage;
  final bool wasCancelled;
  
  MapPickerResult.success(this.location) : errorMessage = null, wasCancelled = false;
  MapPickerResult.error(this.errorMessage) : location = null, wasCancelled = false;
  MapPickerResult.cancelled() : location = null, errorMessage = null, wasCancelled = true;
}
```

---

### Finding Nav-03: Inconsistent Retry Patterns

**Good Pattern (Download Retry):**

**File:** `lib/src/presentation/screens/region_download_screen.dart:355-365`

```dart
// Error state with retry
child: Column(
  children: [
    const Icon(Icons.error_outline, color: Colors.red),
    Text('Download failed: $errorMessage'),
    ElevatedButton(
      onPressed: () => _retryDownload(region),  // ✅ Clear retry action
      child: const Text('Retry'),
    ),
  ],
)
```

**Missing Pattern (Main Screen Errors):**

**File:** `lib/src/presentation/screens/main_screen.dart:296-301`

```dart
// Lines 296-301: SnackBar without retry
try {
  final location = await _controller.getCurrentLocationAddress();
  _originTextController.text = location.name;
  _controller.setOriginLocation(location);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_controller.errorMessage ?? 'Failed to get location'),
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 4),
    ),
  );
}
```

**Gap:** Location errors show SnackBar but no retry option. User must manually re-tap location button.

---

### Finding Err-01: Generic Error Messages

**File:** `lib/src/presentation/screens/main_screen.dart:344-347`

```dart
// Lines 344-347: Generic error message
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_controller.errorMessage ?? 'Failed to get address'),
      // ❌ Same message for all error types
    ),
  );
}
```

**Expected Behavior:** Different errors should show different guidance:
| Error Type | Current Message | Should Show |
|------------|---------------|-------------|
| Permission denied | "Failed to get location" | "Location permission required" + Settings button |
| Network unavailable | "Failed to get address" | "No internet connection" + Offline option |
| Rate limited | "Failed to get address" | "Too many requests. Wait 5s and try again." |

---

### Finding Err-02: Permission Failure Types

**File:** `lib/src/core/errors/failures.dart:28-42`

```dart
// Lines 28-42: Well-typed permission failures
class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([
    super.message = 'Location permission denied. Please grant location access to use this feature.',
  ]);
}

class LocationPermissionDeniedForeverFailure extends Failure {
  const LocationPermissionDeniedForeverFailure([
    super.message = 'Location permission permanently denied. Please enable it in app settings.',
  ]);
}
```

**File:** `lib/src/services/geocoding/geocoding_service.dart:282-305`

```dart
// Lines 282-305: Proper permission flow
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    throw LocationPermissionDeniedFailure();  // ✅ First denial
  }
}
if (permission == LocationPermission.deniedForever) {
  throw LocationPermissionDeniedForeverFailure();  // ✅ Permanent denial
}
```

**Gap:** Typed failures exist but UI only shows generic `errorMessage` string.

---

### Finding Err-04: Silent Failures

**File:** `lib/src/presentation/screens/map_picker_screen.dart:178-209`

```dart
// Lines 178-188: Address loading with error possibility
try {
  _isLoadingAddress.value = true;
  final location = await _geocodingService.getAddressFromLatLng(/* ... */);
  if (mounted) {
    _addressText = location.name;
  }
} catch (e) {
  // ❌ Silent failure - user sees loading stop, no error shown
  debugPrint('Error getting address: $e');
} finally {
  _isLoadingAddress.value = false;
}
```

**Edge Case:** 
1. User moves map to remote location
2. Reverse geocode fails (no Nominatim data)
3. Loading indicator stops
4. User sees old address or coordinates without knowing it failed

---

### Finding Load-01/Load-02: Good Loading Patterns

**File:** `lib/src/presentation/screens/map_picker_screen.dart:46-47, 792-808`

```dart
// Lines 46-47: Dual loading states
final ValueNotifier<bool> _isSearchingLocation = ValueNotifier<bool>(false);
final ValueNotifier<bool> _isLoadingAddress = ValueNotifier<bool>(false);
```

```dart
// Lines 792-808: Animated loading transition
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: ValueListenableBuilder<bool>(
    valueListenable: _isLoadingAddress,
    builder: (context, isLoading, child) {
      if (_isMapMoving) {
        return Text('Moving...', key: const ValueKey('moving'));
      } else if (isLoading && !_offlineModeService.isCurrentlyOffline) {
        return Row(
          key: const ValueKey('loading'),
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Looking up address...'),
          ],
        );
      }
      // ...
    },
  ),
)
```

**Why This Works:**
- Multiple independent loading states
- Smooth transitions with `AnimatedSwitcher`
- Context-aware messaging ("Moving" vs "Looking up address")

---

### Finding Rate-01: Rate Limit Without UX Feedback

**File:** `lib/src/services/geocoding/geocoding_service.dart:47-60`

```dart
// Lines 47-60: Backend throttling only
Future<void> _throttle() async {
  const intervals = {
    GeocodingProvider.nominatim: Duration(milliseconds: 1100),
    GeocodingProvider.locationIQ: Duration(milliseconds: 520),
    GeocodingProvider.geoapify: Duration(milliseconds: 210),
  };
  final minInterval = intervals[_provider]!;
  final last = _lastRequestTime[_provider];
  if (last != null) {
    final elapsed = DateTime.now().difference(last);
    if (elapsed < minInterval) {
      await Future.delayed(minInterval - elapsed);  // ✅ Backend waits
    }
  }
  _lastRequestTime[_provider] = DateTime.now();
}
```

**File:** `lib/src/core/errors/failures.dart:44-48`

```dart
// Lines 44-48: Rate limit failure type
class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Too many requests. Please wait a moment before trying again.',
  ]);
}
```

**Gap:** UI doesn't show:
- When request is being throttled
- How long to wait
- Visual countdown/cooldown indicator

---

### Finding Perm-02/Perm-03: Permission UX Not Implemented

**Evidence - Backend Pattern Only:**

Error types exist (see Err-02 above) but UI code doesn't differentiate:

```dart
// Generic error handling - loses typed failure information
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to get location')),  // ❌ Same for all errors
  );
}

// Should be:
catch (e) {
  if (e is LocationPermissionDeniedFailure) {
    showPermissionRationaleDialog();  // ✅ Explain why needed
  } else if (e is LocationPermissionDeniedForeverFailure) {
    showSettingsDialog();  // ✅ Deep link to settings
  }
}
```

---

### Finding Haptic-01/Haptic-02: Missing Haptic Feedback

**Search Result:** `grep -r "HapticFeedback\|vibrate" lib/`

```
1 matches:
/// connectivity, providing visual feedback to users about their
```

Only comment mentions feedback - no actual haptic implementation.

**Missing Implementation:**

```dart
// SHOULD exist for counter buttons:
// File: lib/src/presentation/widgets/main_screen/passenger_bottom_sheet.dart:147
IconButton(
  icon: Icon(Icons.remove, /* ... */),
  onPressed: () {
    HapticFeedback.lightImpact();  // ✅ Not implemented
    setState(() => _regular--);
  },
  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
)

// SHOULD exist for modal dismiss:
onPressed: () {
  HapticFeedback.selectionClick();  // ✅ Not implemented
  Navigator.of(context).pop();
}
```

---

## Edge Cases Table

| Scenario | Trigger | Current Behavior | Expected Behavior | Risk |
|----------|---------|------------------|-------------------|------|
| Map picker timeout | Slow reverse geocode | Returns coordinates only | Show timeout error, offer coordinates-as-address | Confusion |
| Double-tap search button | Rapid user action | Throttled silently | Visual cooldown indicator | User confusion, perceived unresponsiveness |
| Permission denied forever | User denies twice | Generic error | Settings deep-link prompt | User cannot recover |
| Network blip during calculation | Temporary disconnection | Silent fallback to cache | Show "Using offline data" indicator | User unaware of accuracy change |
| App background during download | User switches apps | Download pauses/resumes | Notification with progress | Download never completes |
| Screen rotation during modal | Device rotation | Modal may resize awkwardly | Maintain state, smooth transition | State loss |
| System font size 200% | User accessibility setting | Layout overflow | Scrollable layouts, max constraints | Unusable UI |
| Battery saver mode | System restriction | Location updates slower | Graceful degradation message | Unexpected behavior |
| Geocoding returns empty result | Remote location | Shows coordinates | "Location name unavailable" with coordinates | Confusion |
| Rate limit hit mid-session | Multiple searches | Pauses then continues | Immediate feedback + retry timer | Spam behavior |

---

## Recommendations

### Priority P0 (Fix Immediately)

1. **Rate-01 + Rate-02:** Add visual rate limit indicator
   - Show countdown in search field
   - Disable button during throttle with visual state

2. **Err-01 + Err-04:** Implement error messaging component
   - Map Failure types to user-friendly, actionable messages
   - Never swallow errors silently

### Priority P1 (Next Sprint)

3. **Nav-01:** Return structured result objects from navigation
   - Include error context in return values
   - Handle all error paths explicitly

4. **Perm-02 + Perm-03:** Implement permission UX patterns
   - Rationale dialog for first denial
   - Settings deep-link for permanent denial

5. **Retry-03:** Add retry action to all error SnackBars
   - Consistent "Try Again" button pattern

### Priority P2 (This Month)

6. **Haptic-01 + Haptic-02:** Add haptic feedback
   - Light impact for increment/decrement
   - Selection click for button presses
   - Success pattern for save completion

7. **Load-03:** Add download progress indicator
   - Percentage + bytes remaining
   - Cancel option

8. **Empty-01 + Empty-02:** Define empty state patterns
   - Illustrations + clear messaging
   - Action buttons where applicable

---

## Pattern Library

### Recommended: Error Dialog with Retry

```dart
Future<void> showErrorWithRetry(BuildContext context, String message, VoidCallback onRetry) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.error_outline, color: Colors.red),
      title: const Text('Something went wrong'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onRetry();
          },
          child: const Text('Try Again'),
        ),
      ],
    ),
  );
}
```

### Recommended: Loading Shimmer

```dart
class ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 16,
        color: Colors.white,
      ),
    );
  }
}
```

### Recommended: Rate Limit Indicator

```dart
class RateLimitIndicator extends StatelessWidget {
  final int remainingSeconds;
  
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.timer),
      label: Text('Wait ${remainingSeconds}s'),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    );
  }
}
```

---

## Success Criteria

- ✅ All errors have actionable messages
- ✅ All loading states include context
- ✅ Rate limiting has visual feedback
- ✅ Permission denials have recovery paths
- ✅ Retry available on all recoverable errors
- ✅ Haptic feedback on key interactions
- ✅ Navigation results include error context

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-17 | Initial navigation, error, and feedback patterns documentation |
