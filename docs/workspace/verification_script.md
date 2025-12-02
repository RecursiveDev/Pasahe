# Manual Verification Script

## Test Environment Setup

**Prerequisites:**
- Flutter development environment configured
- Physical device or emulator with internet connectivity
- Philippines location access (for realistic geocoding results)

**Launch Application:**
```bash
flutter run
```

---

## Test Case 1: Autocomplete Suggestions with Debouncing

### Objective
Verify that autocomplete suggestions appear for location searches and that debouncing prevents excessive API calls.

### Steps
1. Launch the application
2. Tap on the "Origin" text field
3. Type slowly: "M" → wait → "a" → wait → "n"
4. **Expected:** No suggestions appear while typing (debouncing active)
5. Wait 800ms after typing stops
6. **Expected:** Autocomplete suggestions dropdown appears with locations matching "Man" (e.g., "Manila", "Mandaluyong", "Mandaue")
7. Continue typing: "ila"
8. **Expected:** Previous suggestions disappear, new debounce timer starts
9. Wait 800ms
10. **Expected:** Updated suggestions appear matching "Manila"

### Success Criteria
- ✅ No API calls made during rapid typing (check network tab if using browser/debugger)
- ✅ Suggestions appear only after 800ms pause
- ✅ Suggestions are relevant to typed text
- ✅ Suggestions are limited to Philippines locations

### Notes
- Debounce duration: 800ms as per implementation
- API used: OpenStreetMap Nominatim (respects 1 req/sec limit)

---

## Test Case 2: Map Moves to Selected Origin

### Objective
Verify that the map camera automatically pans to show the selected origin location.

### Steps
1. In the "Origin" field, type "NAIA" (Ninoy Aquino International Airport)
2. Wait for autocomplete suggestions
3. **Expected:** List shows "Ninoy Aquino International Airport" or similar
4. Tap the suggestion to select it
5. **Expected:** Map widget below immediately pans to show the airport location
6. **Expected:** Green marker appears on the map at the origin location
7. **Expected:** Map is centered approximately on the marker

### Success Criteria
- ✅ Map camera moves smoothly to origin location
- ✅ Green origin marker is visible
- ✅ Map zoom level is appropriate to see the location clearly
- ✅ No errors displayed

---

## Test Case 3: Map Moves to Selected Destination

### Objective
Verify that the map adjusts to show both origin and destination when destination is selected.

### Prerequisites
- Origin already selected (from Test Case 2)

### Steps
1. In the "Destination" field, type "SM Mall of Asia"
2. Wait for autocomplete suggestions
3. **Expected:** List shows mall locations
4. Tap a suggestion to select it
5. **Expected:** Map immediately adjusts view to fit both origin and destination
6. **Expected:** Red destination marker appears on the map
7. **Expected:** Both green (origin) and red (destination) markers are visible

### Success Criteria
- ✅ Map fits bounds to show both markers
- ✅ Red destination marker is visible
- ✅ Green origin marker still visible
- ✅ Map zoom adjusts appropriately to show both locations

---

## Test Case 4: Route Polyline Visualization

### Objective
Verify that a blue route polyline appears connecting origin and destination.

### Prerequisites
- Both origin and destination selected (from Test Cases 2-3)

### Steps
1. After selecting destination, observe the map
2. **Expected:** A blue polyline appears on the map within 1-2 seconds
3. **Expected:** The polyline connects the origin (green marker) to destination (red marker)
4. **Expected:** The polyline follows roads/paths (not a straight line)
5. Zoom in on the route
6. **Expected:** Route shows realistic road geometry

### Success Criteria
- ✅ Blue polyline is visible
- ✅ Route follows actual roads (OSRM routing)
- ✅ Route connects both markers
- ✅ Polyline width is 4px (easily visible but not overwhelming)

### Edge Case Testing
**No Route Available:**
1. Set origin to "Manila"
2. Set destination to an island with no ferry connection (e.g., remote island)
3. **Expected:** No polyline appears, but no error shown to user
4. **Expected:** User can still click "Calculate Fare" button

---

## Test Case 5: Fare Calculation Trigger and Results

### Objective
Verify that fare calculation can be triggered and displays reasonable results.

### Prerequisites
- Origin: "NAIA Terminal 3" (approx. 14.507, 121.020)
- Destination: "SM Mall of Asia" (approx. 14.535, 120.982)
- Route distance: ~5-6 km

### Steps
1. Ensure both origin and destination are selected
2. Ensure route polyline is visible on map
3. Tap the "Calculate Fare" button
4. **Expected:** Button shows loading state briefly
5. **Expected:** Fare results appear below the map
6. **Expected:** Results show multiple transport modes (e.g., Jeepney, Taxi)
7. **Expected:** Fare amounts are reasonable:
   - Jeepney: ₱13-20 (base fare ~₱13 + per-km rate)
   - Taxi: ₱50-80 (base fare ~₱40 + per-km + traffic)

### Success Criteria
- ✅ Fare results appear after calculation
- ✅ Multiple transport modes displayed
- ✅ Fare amounts are numerically reasonable
- ✅ No error messages appear
- ✅ Indicator level shows (e.g., "Normal", "High" for traffic)

### Validation
**Distance Check:**
- Route distance should be approximately 5-6 km (can verify in debugger/logs)
- Fare should increase proportionally with distance

**Formula Verification:**
- Jeepney: base ₱13 + (distance_km * ₱1.80/km)
- Taxi: base ₱40 + (distance_km * ₱13.50/km) + traffic multiplier

---

## Test Case 6: Autocomplete Empty Input Handling

### Objective
Verify that no API calls are made for empty input.

### Steps
1. Clear the "Origin" field
2. **Expected:** No autocomplete suggestions appear
3. Type a single space character
4. **Expected:** No suggestions appear (trimmed to empty)
5. Type a valid search term
6. **Expected:** Normal autocomplete behavior resumes

### Success Criteria
- ✅ No suggestions for empty/whitespace input
- ✅ No unnecessary API calls

---

## Test Case 7: Map Interaction During Route Calculation

### Objective
Verify that users can interact with the map while route calculation is in progress.

### Steps
1. Select origin and destination (triggers route calculation)
2. Immediately pan/zoom the map
3. **Expected:** Map responds to user gestures
4. **Expected:** When route loads, polyline appears but doesn't disrupt view
5. **Expected:** No crashes or freezing

### Success Criteria
- ✅ Map remains interactive during async operations
- ✅ Route polyline appears without jarring camera movements
- ✅ Smooth user experience

---

## Test Case 8: Changing Locations After Fare Calculation

### Objective
Verify that changing origin or destination clears previous results and recalculates route.

### Prerequisites
- Fare already calculated from previous test

### Steps
1. Observe existing fare results displayed
2. Change the "Origin" to a different location
3. **Expected:** Fare results immediately disappear
4. **Expected:** Route polyline is cleared from map
5. **Expected:** Origin marker moves to new location
6. Wait for destination to still be selected
7. **Expected:** New route polyline appears automatically
8. Click "Calculate Fare" again
9. **Expected:** New fare results based on updated route

### Success Criteria
- ✅ Old results cleared when locations change
- ✅ Route recalculates automatically
- ✅ New fare reflects new route distance

---

## Test Case 9: Save Route Functionality

### Objective
Verify that calculated routes can be saved.

### Prerequisites
- Fare results displayed

### Steps
1. After calculating fare, locate "Save Route" button
2. **Expected:** Button is visible and enabled
3. Tap "Save Route"
4. **Expected:** Snackbar message appears: "Route saved successfully" (or similar)
5. Navigate to saved routes (if accessible in app)
6. **Expected:** Recently saved route appears in list

### Success Criteria
- ✅ Route saves without errors
- ✅ User receives confirmation
- ✅ Route can be retrieved later

---

## Test Case 10: Network Resilience - Offline Geocoding

### Objective
Verify graceful handling when geocoding service is unavailable.

### Steps
1. Enable airplane mode or disable internet
2. Type in "Origin" field: "Manila"
3. Wait 800ms
4. **Expected:** No suggestions appear
5. **Expected:** No crash or error dialog
6. Re-enable internet
7. Clear field and type "Manila" again
8. **Expected:** Suggestions reappear normally

### Success Criteria
- ✅ No crashes when API unavailable
- ✅ Graceful degradation
- ✅ Recovery when connection restored

---

## Performance Benchmarks

### Autocomplete Response Time
- **Target:** Suggestions appear within 100-300ms after debounce completes
- **Measure:** Time from last keystroke + 800ms to suggestions display

### Route Calculation Time
- **Target:** Polyline appears within 2 seconds after destination selection
- **Measure:** Time from destination selection to route rendering

### Map Rendering
- **Target:** Smooth 60fps during pan/zoom
- **Visual Test:** No stuttering or lag during map interaction

---

## Accessibility Testing

### Screen Reader Support
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate to Origin field
3. **Expected:** Announces "Input for Origin location"
4. Navigate to Calculate button
5. **Expected:** Announces "Calculate Fare based on selected origin and destination"
6. **Expected:** Button state (enabled/disabled) is announced

### Keyboard Navigation (if applicable)
- Tab order follows logical flow: Origin → Destination → Calculate
- All interactive elements reachable via keyboard

---

## Summary Checklist

Before declaring the feature complete, verify:

- [ ] Debouncing prevents rapid API calls (800ms delay confirmed)
- [ ] Autocomplete suggestions are relevant and Philippines-specific
- [ ] Map pans to origin when selected
- [ ] Map fits bounds for both origin and destination
- [ ] Blue route polyline displays correctly
- [ ] Route follows actual roads (OSRM geometry)
- [ ] Fare calculation produces reasonable amounts
- [ ] Multiple transport modes displayed
- [ ] Results cleared when locations change
- [ ] Save route functionality works
- [ ] Graceful handling of network failures
- [ ] No crashes under normal usage
- [ ] Accessibility features functional

---

## Known Limitations to Document

1. **OSRM Public Server:** Not suitable for production heavy load
2. **Map Tiles:** OpenStreetMap tile usage policy must be reviewed for production
3. **Route Visualization:** May fail silently if OSRM unreachable (fare calc still works via Haversine)
4. **Debounce Timing:** Fixed at 800ms (not user-configurable)

---

## Test Execution Log Template

| Test Case | Tester | Date | Result | Notes |
|-----------|--------|------|--------|-------|
| TC1: Autocomplete | | | ☐ Pass ☐ Fail | |
| TC2: Map to Origin | | | ☐ Pass ☐ Fail | |
| TC3: Map to Destination | | | ☐ Pass ☐ Fail | |
| TC4: Route Polyline | | | ☐ Pass ☐ Fail | |
| TC5: Fare Calculation | | | ☐ Pass ☐ Fail | |
| TC6: Empty Input | | | ☐ Pass ☐ Fail | |
| TC7: Map Interaction | | | ☐ Pass ☐ Fail | |
| TC8: Location Changes | | | ☐ Pass ☐ Fail | |
| TC9: Save Route | | | ☐ Pass ☐ Fail | |
| TC10: Network Resilience | | | ☐ Pass ☐ Fail | |