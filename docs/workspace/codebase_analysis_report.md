# Codebase Analysis Report: Discount, Filtering, and Map Features

**Date:** 2025-12-02
**Subtask:** analysis-001
**Status:** Complete

## 1. Executive Summary
This analysis reviewed the PH Fare Estimator codebase to identify integration points for three new features: User Discounts (Student/Senior/PWD), Transport Mode Filtering, and Map Selection improvements. 

**Key Findings:**
*   **Fare Logic:** The core calculation resides in `HybridEngine.calculateDynamicFare` (`lib/src/core/hybrid_engine.dart`). It currently handles distance variance, provincial toggles, and traffic factors but lacks any implementation for user-type discounts (20%).
*   **Transport Modes:** Modes are defined in `TransportMode` enum and detailed in `assets/data/fare_formulas.json`. The `MainScreen` currently uses a hardcoded list of modes for comparison, ignoring the rich data available in the JSON or the recommendation logic in `FareComparisonService`.
*   **Location/Map:** `MapSelectionWidget` and `GeocodingService` are well-implemented. `MainScreen` integrates them but lacks a dedicated "Select on Map" flow for better UX.
*   **Settings:** `SettingsService` exists but needs to be expanded to store the User Type (for discounts) and Preferred Modes (for filtering).

---

## 2. Detailed Analysis

### A. Fare Calculation Logic
**Current Implementation:**
*   **File:** [`lib/src/core/hybrid_engine.dart`](lib/src/core/hybrid_engine.dart)
*   **Method:** `calculateDynamicFare`
*   **Formula:** `Total = Base + (Distance * 1.15 * PerKm)`
*   **Existing Modifiers:**
    *   *Provincial Mode:* +20% for Jeepneys.
    *   *Traffic Factor:* 0.9x - 1.2x for Taxis.
    *   *Minimum Fare:* Enforced if defined in formula.

**Required Changes for Discounts:**
1.  **New Input:** `calculateDynamicFare` needs a new parameter `DiscountType` (None, Student, Senior, PWD).
2.  **Logic:** Apply 20% discount logic as defined in [`docs/research/discount_rates_ph.md`](docs/research/discount_rates_ph.md).
    *   *Formula:* `DiscountedTotal = Total * 0.80`.
    *   *Constraint:* Ensure discount applies to the final computed fare (Base + Distance).
3.  **Static Fares:** `calculateStaticFare` (Trains/Ferries) also needs to accept `DiscountType` since these modes strictly honor mandated discounts.

### B. Transport Mode Models & Filtering
**Current Implementation:**
*   **Models:**
    *   [`TransportMode`](lib/src/models/transport_mode.dart) (Enum): High-level categories.
    *   [`FareFormula`](lib/src/models/fare_formula.dart) (Class): Specific subtypes (e.g., "Traditional Jeepney") loaded from JSON.
*   **Data Source:** [`assets/data/fare_formulas.json`](assets/data/fare_formulas.json).
*   **Current Usage:** `MainScreen` (`lib/src/presentation/screens/main_screen.dart`) compares a **hardcoded list**:
    ```dart
    final modesToCompare = [
      {'mode': 'Jeepney', 'subType': 'Traditional'},
      {'mode': 'Taxi', 'subType': 'White (Regular)'},
    ];
    ```

**Required Changes for Filtering:**
1.  **Dynamic Selection:** Replace the hardcoded `modesToCompare` in `MainScreen` with a dynamic list derived from `FareRepository.getAllFormulas()`.
2.  **Filter Logic:**
    *   Implement filtering based on user preferences (e.g., "Show only Aircon", "Exclude Taxis").
    *   Integrate `FareComparisonService.recommendModes` to prioritize relevant modes based on distance (e.g., hide Tricycles for >20km trips).

### C. Location Selection & Map
**Current Implementation:**
*   **Files:**
    *   [`lib/src/presentation/screens/main_screen.dart`](lib/src/presentation/screens/main_screen.dart)
    *   [`lib/src/presentation/widgets/map_selection_widget.dart`](lib/src/presentation/widgets/map_selection_widget.dart)
    *   [`lib/src/services/geocoding/geocoding_service.dart`](lib/src/services/geocoding/geocoding_service.dart)
*   **Functionality:**
    *   Autocomplete text fields are primary.
    *   Map widget displays route and allows tap-to-select for Origin/Destination.
    *   `MainScreen` manages state synchronization between text fields and map taps.

**Required Changes:**
*   The current implementation is functional but the UX could be improved. The map is always visible but small (height: 300).
*   **Refinement:** No major architectural changes needed here, mostly UI polish to ensure the "Map Selection" feels like a first-class citizen alongside text search.

### D. User Settings & Preferences
**Current Implementation:**
*   **File:** [`lib/src/services/settings_service.dart`](lib/src/services/settings_service.dart)
*   **Storage:** `SharedPreferences`.
*   **Keys:** `isProvincialModeEnabled`, `trafficFactor`, `isHighContrastEnabled`, `locale`.

**Required Changes:**
1.  **User Profile:** Add `userType` (enum: Standard, Student, Senior, PWD) to `SettingsService`.
2.  **Persistence:** Save/Load this preference so discounts apply automatically on app restart.
3.  **UI:** Update [`lib/src/presentation/screens/settings_screen.dart`](lib/src/presentation/screens/settings_screen.dart) to include a dropdown or selector for User Type.

---

## 3. Implementation Plan Reference

### Step 1: Data Models & Settings (Backend)
*   **Target:** `SettingsService`, `FareFormula` (if flag needed for discount eligibility, though usually applies to all).
*   **Task:** Add `UserType` enum and storage.

### Step 2: Core Logic (Engine)
*   **Target:** `HybridEngine`.
*   **Task:** Update `calculateDynamicFare` and `calculateStaticFare` to accept `UserType` and apply 20% math.

### Step 3: UI Integration (Frontend)
*   **Target:** `MainScreen` & `SettingsScreen`.
*   **Task:**
    *   Add "Passenger Type" selector in Settings (or Main Screen for quick toggle).
    *   Make mode comparison dynamic (fetch all formulas -> filter -> calculate).
    *   Display "Discounted" tag on `FareResultCard` if applied.
