# Implementation Plan v2: Discounts, Filtering, and Map Selection

**Date:** 2025-12-02
**Version:** 2.0
**Status:** Approved for Implementation

## 1. Executive Summary
This plan details the technical design for three key features: User Discount logic (20% for Student/Senior/PWD), Transport Mode Filtering (dynamic vs hardcoded lists), and an enhanced Map Selection flow. The design leverages the existing `HybridEngine` for calculations, `SettingsService` for persistence, and introduces a cleaner UI workflow for location selection.

---

## 2. Technical Architecture

### A. Discount Logic (Core Engine)

**Objective:** Apply a 20% discount to fares for eligible user types (Student, Senior, PWD).

1.  **New Enum: `DiscountType`**
    *   **Location:** `lib/src/models/discount_type.dart` (New File)
    *   **Values:** `standard` (default), `student`, `senior`, `pwd`.
    *   **Extension:** `displayName` property for UI.

2.  **Settings Service Update:**
    *   **File:** `lib/src/services/settings_service.dart`
    *   **New Key:** `_keyUserType = 'userType'`
    *   **Methods:** `Future<DiscountType> getUserType()`, `Future<void> setUserType(DiscountType type)`.
    *   **State Management:** Add `ValueNotifier<DiscountType>` for reactive UI updates.

3.  **Engine Update: `HybridEngine`**
    *   **File:** `lib/src/core/hybrid_engine.dart`
    *   **Method:** `calculateDynamicFare`
    *   **Logic Change:**
        ```dart
        // After calculating totalFare (Base + Distance + Provincial + Traffic)
        // Apply 20% discount if eligible
        final userType = await _settingsService.getUserType();
        if (userType != DiscountType.standard) {
          totalFare *= 0.80; 
        }
        ```
    *   **Note:** `calculateStaticFare` (Trains/Ferries) will also receive this logic since they are legally mandated.

4.  **UI Update: `FareResultCard`**
    *   **File:** `lib/src/presentation/widgets/fare_result_card.dart`
    *   **Change:** Add a visual badge "20% Discount Applied" if the calculated fare includes the discount.

### B. Transport Mode Filtering

**Objective:** Allow users to filter which transport modes are displayed (e.g., "Hide Taxis").

1.  **New Model: `TransportFilter`**
    *   **Location:** `lib/src/models/transport_filter.dart` (New File)
    *   **Properties:** `Map<TransportMode, bool> isEnabled`.

2.  **Settings Service Update:**
    *   **File:** `lib/src/services/settings_service.dart`
    *   **New Key:** `_keyTransportFilters` (Stored as JSON string).
    *   **Methods:** `Future<Map<String, bool>> getTransportFilters()`, `Future<void> updateTransportFilter(String mode, bool isEnabled)`.

3.  **Main Screen Logic:**
    *   **File:** `lib/src/presentation/screens/main_screen.dart`
    *   **Current State:** Hardcoded `modesToCompare`.
    *   **New State:**
        1.  Fetch all formulas via `_fareRepository.getAllFormulas()`.
        2.  Fetch user filters via `_settingsService`.
        3.  Filter the formulas: `formulas.where((f) => filters[f.mode] == true)`.
        4.  Calculate fares only for the filtered list.

### C. Map Selection Flow

**Objective:** specific "Pick from Map" flow rather than the always-visible small map.

1.  **New Screen: `MapPickerScreen`**
    *   **Location:** `lib/src/presentation/screens/map_picker_screen.dart` (New File)
    *   **Purpose:** Full-screen map with a "Confirm Location" floating button.
    *   **Returns:** `LatLng` (and optionally `Location` object if reverse geocoding happens inside).

2.  **Widget Update: `MainScreen`**
    *   **File:** `lib/src/presentation/screens/main_screen.dart`
    *   **Change:**
        *   Replace the inline `MapSelectionWidget` (height: 300) with a "Select on Map" icon button inside the text fields (suffix icon).
        *   **Flow:**
            1.  User taps "Map" icon in "Origin" field.
            2.  Navigates to `MapPickerScreen(initialLocation: currentOrigin)`.
            3.  User pans/zooms and taps a point. Marker updates.
            4.  User taps "Confirm".
            5.  Screen pops with `LatLng`.
            6.  `MainScreen` receives `LatLng`, calls `GeocodingService.getAddress(latLng)`, and updates the text field + state.

---

## 3. Step-by-Step Implementation Guide

### Phase 1: Models & Settings (Foundation)
1.  **Create `lib/src/models/discount_type.dart`**.
2.  **Update `SettingsService`**:
    *   Add persistence for `DiscountType`.
    *   Add persistence for Transport Mode filters (Map<String, bool>).
3.  **Update `SettingsScreen`**:
    *   Add "Passenger Type" dropdown (Student, Senior, PWD, Regular).
    *   Add "Transport Modes" checkboxes (Toggle Jeepney, Bus, Taxi, etc.).

### Phase 2: Engine & Logic
4.  **Update `HybridEngine`**:
    *   Inject `SettingsService` (already there).
    *   Modify `calculateDynamicFare` to check `_settingsService.getUserType()` and apply 0.8x multiplier.
    *   Add unit tests for discount calculation.

### Phase 3: UI & Map Integration
5.  **Create `MapPickerScreen`**:
    *   Use `flutter_map`.
    *   Implement tap-to-mark logic.
    *   Return data on pop.
6.  **Refactor `MainScreen`**:
    *   Remove fixed-height map widget.
    *   Add map icon to `_buildLocationAutocomplete`.
    *   Implement `_openMapPicker(isOrigin)` method.
    *   Update `_calculateFare` to use dynamic list of formulas filtered by settings.

---

## 4. Verification Plan

*   **Discount Check:** Set user type to "Student". Calculate fare. Verify result is 20% less than "Regular".
*   **Filter Check:** Uncheck "Taxi" in settings. Calculate fare. Verify Taxi results are absent.
*   **Map Check:** Open Map Picker, select a point, confirm. Verify address text fills the input field.