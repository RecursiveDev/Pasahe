# Manual Verification Checklist - New Features QA

**Project:** PH Fare Estimator  
**Features:** Discount Logic, Transport Mode Filtering, Map Picker  
**Date:** 2025-12-02  
**QA Engineer:** Automated QA System

---

## Prerequisites

- [ ] App installed and running on device/emulator
- [ ] Internet connection available for map tiles
- [ ] Freshly cleared app data (for clean state testing)

---

## Feature 1: Discount Logic (20% for Student/Senior/PWD)

### Test Case 1.1: Apply Student Discount
**Steps:**
1. Open the app
2. Tap Settings (gear icon in top-right)
3. Scroll to "Passenger Type" section
4. Select "Student" radio button
5. Return to main screen
6. Enter Origin: "Ninoy Aquino International Airport"
7. Enter Destination: "SM Mall of Asia"
8. Tap "Calculate Fare"

**Expected Results:**
- [ ] Student discount option is selected in settings
- [ ] Settings shows "20% discount (RA 11314)" subtitle
- [ ] Fare results show reduced prices (20% less than regular)
- [ ] All transport modes show discounted fares

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 1.2: Apply Senior Citizen Discount
**Steps:**
1. Go to Settings
2. Select "Senior Citizen" under Passenger Type
3. Return to main screen
4. Calculate same route as above

**Expected Results:**
- [ ] Senior discount is selected
- [ ] Fares are 20% less than standard
- [ ] Discount applies to all modes (Jeepney, Bus, Taxi, etc.)

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 1.3: Apply PWD Discount
**Steps:**
1. Go to Settings
2. Select "PWD" under Passenger Type
3. Return to main screen
4. Calculate same route

**Expected Results:**
- [ ] PWD discount is selected
- [ ] Fares show 20% discount
- [ ] "20% discount (RA 7277)" subtitle visible

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 1.4: Switch Back to Regular (No Discount)
**Steps:**
1. Go to Settings
2. Select "Regular" under Passenger Type
3. Return to main screen
4. Calculate same route

**Expected Results:**
- [ ] Regular fare is selected
- [ ] Fares show full price (no discount)
- [ ] "No discount" subtitle visible

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 1.5: Discount Persists After App Restart
**Steps:**
1. Set discount to "Student"
2. Close app completely (force stop)
3. Reopen app
4. Go to Settings

**Expected Results:**
- [ ] Student discount is still selected
- [ ] Discount applies to calculations

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

---

## Feature 2: Transport Mode Filtering

### Test Case 2.1: View All Transport Modes
**Steps:**
1. Go to Settings
2. Scroll to "Transport Modes" section

**Expected Results:**
- [ ] "Transport Modes" header is visible
- [ ] Multiple transport modes listed (Jeepney, Bus, Taxi, etc.)
- [ ] Each mode has subtypes (e.g., "Traditional", "Modern")
- [ ] All switches are ON by default

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 2.2: Hide a Transport Mode (Taxi)
**Steps:**
1. In Settings > Transport Modes
2. Find "Taxi" section
3. Turn OFF the "Regular" taxi switch
4. Return to main screen
5. Enter valid origin and destination
6. Calculate fare

**Expected Results:**
- [ ] Taxi switch is OFF
- [ ] Fare results do NOT include any Taxi options
- [ ] Other modes (Jeepney, Bus) still appear

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 2.3: Hide Multiple Modes
**Steps:**
1. In Settings > Transport Modes
2. Turn OFF "Jeepney > Traditional"
3. Turn OFF "Bus > Ordinary"
4. Return to main screen
5. Calculate fare

**Expected Results:**
- [ ] Hidden modes do NOT appear in results
- [ ] Only enabled modes show fares
- [ ] At least one mode remains enabled

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 2.4: Re-enable Hidden Modes
**Steps:**
1. Go back to Settings
2. Turn ON previously disabled modes
3. Return to main screen
4. Calculate fare

**Expected Results:**
- [ ] All modes appear again in results
- [ ] Fares calculate correctly for re-enabled modes

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 2.5: Hide All Modes (Error Handling)
**Steps:**
1. In Settings, turn OFF all transport mode switches
2. Return to main screen
3. Try to calculate fare

**Expected Results:**
- [ ] Error message displayed: "No transport modes enabled. Please enable at least one mode in Settings."
- [ ] No fare calculation occurs
- [ ] User can navigate back to Settings to fix

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 2.6: Filter Persistence
**Steps:**
1. Hide "Taxi" mode
2. Close app completely
3. Reopen app
4. Go to Settings

**Expected Results:**
- [ ] Taxi mode is still OFF
- [ ] Other settings remain unchanged

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

---

## Feature 3: Map Picker Integration

### Test Case 3.1: Open Map Picker for Origin
**Steps:**
1. On main screen, focus on "Origin" field
2. Tap the map icon (on the right side of the field)

**Expected Results:**
- [ ] Map Picker screen opens full-screen
- [ ] Map shows Manila area (default center)
- [ ] "Select Origin" title in app bar
- [ ] Crosshair/marker visible on map
- [ ] "Confirm Location" button at bottom
- [ ] Instructions card at top

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 3.2: Pan and Select Location on Map
**Steps:**
1. Open Map Picker for Origin
2. Pan the map to a different location
3. Tap anywhere on the map
4. Tap "Confirm Location"

**Expected Results:**
- [ ] Marker moves to tapped location
- [ ] Map pans smoothly
- [ ] After confirmation, returns to main screen
- [ ] Origin field populates with address
- [ ] Loading indicator briefly shows while geocoding

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 3.3: Open Map Picker for Destination
**Steps:**
1. On main screen, focus on "Destination" field
2. Tap the map icon
3. Select a location different from origin
4. Confirm

**Expected Results:**
- [ ] Map Picker opens with "Select Destination" title
- [ ] Can select location independently
- [ ] Destination field populates
- [ ] Both origin and destination markers visible on main map

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 3.4: Cancel Map Selection
**Steps:**
1. Open Map Picker
2. Tap back arrow or swipe to go back without confirming

**Expected Results:**
- [ ] Returns to main screen
- [ ] Previous location data unchanged

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case 3.5: Map Picker with No Internet
**Steps:**
1. Turn OFF internet connection
2. Try to open Map Picker

**Expected Results:**
- [ ] Map tiles may not load (shows gray tiles)
- [ ] Can still tap to place marker
- [ ] Geocoding will fail (address not retrieved)
- [ ] Error message shown when trying to confirm

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

---

## Integration Tests: Combined Features

### Test Case INT-1: Discount + Filtering Together
**Steps:**
1. Set discount to "Student"
2. Hide "Taxi" mode
3. Calculate fare for any route

**Expected Results:**
- [ ] Only non-Taxi modes appear
- [ ] All shown fares have 20% discount
- [ ] No Taxi results visible

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Test Case INT-2: All Features Combined
**Steps:**
1. Set discount to "PWD"
2. Hide "Bus" modes
3. Use Map Picker to select origin
4. Use Map Picker to select destination
5. Calculate fare

**Expected Results:**
- [ ] Both locations selected via map
- [ ] Route displays on main map
- [ ] Fare results exclude Bus
- [ ] All fares show 20% PWD discount

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

---

## Edge Cases & Error Scenarios

### Edge Case 1: Very Short Distance with Discount
**Steps:**
1. Set discount to "Senior"
2. Select two very close locations (< 1km apart)
3. Calculate fare

**Expected Results:**
- [ ] Minimum fare applies
- [ ] Discount still reduces minimum fare by 20%
- [ ] No errors or crashes

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

### Edge Case 2: Change Settings Mid-Calculation
**Steps:**
1. Start fare calculation
2. While loading, go to Settings
3. Change discount type
4. Return to results

**Expected Results:**
- [ ] App handles gracefully
- [ ] No crashes
- [ ] Next calculation uses new settings

**Pass/Fail:** ☐ Pass ☐ Fail  
**Notes:** _______________________________________________

---

## Final Checklist

Before approving the release:

- [ ] All discount types work correctly
- [ ] Transport filtering functions properly
- [ ] Map picker is accessible and usable
- [ ] Settings persist across app restarts
- [ ] No crashes encountered during testing
- [ ] UI is responsive and intuitive
- [ ] Error messages are clear and helpful
- [ ] All three features work together seamlessly

---

## Issues Found

**Issue #1:**  
Description: _______________________________________________  
Severity: ☐ Critical ☐ High ☐ Medium ☐ Low  
Steps to Reproduce: _______________________________________________

**Issue #2:**  
Description: _______________________________________________  
Severity: ☐ Critical ☐ High ☐ Medium ☐ Low  
Steps to Reproduce: _______________________________________________

---

## Sign-Off

**Tested By:** _____________________________  
**Date:** _____________________________  
**Overall Result:** ☐ PASS ☐ FAIL (with issues)  
**Approved for Release:** ☐ YES ☐ NO

**Notes:** _______________________________________________