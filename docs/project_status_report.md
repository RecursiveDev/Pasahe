# Project Status Report: PH Fare Calculator

## Executive Summary
The **PH Fare Calculator** project is in a robust **beta state**. The Core "Hybrid Calculation Engine" is fully implemented, successfully handling both dynamic road-based calculations (via OSRM) and static matrix lookups. The primary user flows—Onboarding, Search, Fare Calculation, and Offline Reference—are functional. The project adheres well to the PRD's technical stack, utilizing Flutter, Firebase, and Hive as specified. However, the app is **not yet production-ready** due to incomplete feature sets in the Onboarding flow (Language selection is non-functional) and a lack of user feedback mechanisms for API errors.

## Features Implemented

### Core Logic & Engine
- **Hybrid Calculation Engine**: `lib/src/core/hybrid_engine.dart` correctly orchestrates logic for:
  - **Dynamic Fares**: Calculates Jeepney, Bus, and Taxi fares using OSRM distance data + variance multipliers (1.15x).
  - **Static Fares**: Supports Train and Ferry lookups from JSON assets.
  - **Adjustments**: Correctly applies "Provincial Mode" (+20% for Jeeps) and "Traffic Factor" (Taxi multipliers).
- **Routing Service**: `OsrmRoutingService` successfully integrates with the OSRM demo API.
- **Geocoding**: `OpenStreetMapGeocodingService` implements location search restricted to the Philippines.

### User Interface
- **Main Screen**: Functional Autocomplete for Origin/Destination, "Calculate Fare" action, and Result Cards showing price ranges (Standard/Peak/Tourist Trap).
- **Settings**: Toggles for Provincial Mode, High Contrast Mode, and Traffic Factor selection are fully wired to `SettingsService`.
- **Offline Capabilities**:
  - **Saved Routes**: Users can save calculated routes to Hive local storage (`SavedRoute` model).
  - **Reference Menu**: Navigation to "Static Cheat Sheets" and "Saved Routes" is implemented.
- **Onboarding**: Splash screen and introductory slides exist.

### Data & Configuration
- **Remote Config**: Basic setup in `RemoteConfigService` to fetch formulas from Firebase.
- **Local Persistence**: `FareCacheService` successfully handles Hive boxes for `FareFormula` and `SavedRoute`.

## Missing Features / Gaps
1.  **Language Selection**:
    -   In `lib/src/presentation/screens/onboarding_screen.dart`, the buttons for "English" and "Tagalog" exist but have empty `onPressed: () {}` handlers. The app does not currently support localization.
2.  **Comparison View**:
    -   `lib/src/presentation/screens/main_screen.dart` currently hardcodes the comparison to just 'Jeepney (Traditional)' and 'Taxi (White)'. It does not dynamically suggest 'Bus' or 'Train' based on distance or location, nor does it allow the user to filter modes.
3.  **Error Handling & Feedback**:
    -   `GeocodingService` returns an empty list `[]` on exceptions, providing no feedback to the user if the API is down or the network fails.
    -   `RemoteConfigService` logs errors to the console but defaults silently without notifying the user if config fetch fails.
4.  **Static Data Update**:
    -   While the engine *can* load JSONs, the `RemoteConfigService` sets defaults but the parsing logic to strictly update the local Hive cache from Remote Config updates is not fully visible in the inspected files.

## Technical Debt & Code Quality
*Although no explicit "TODO" comments were found, the following implicit debt exists:*

-   **Hardcoded Comparison Logic**: The `_calculateFare` method in `MainScreen` (Line 307) explicitly lists specific modes to compare. This should be dynamic based on the available formulas or user preference.
-   **String Matching Fragility**: `calculateStaticFare` in `HybridEngine` (Line 108) relies on exact string equality (`toLowerCase()`). This may be brittle for user-entered text versus stored JSON keys (e.g., "Taft" vs "Taft Ave").
-   **Service Instantiation**: `MainScreen` instantiates services directly in `initState` if not provided via constructor. Dependency Injection (using `GetIt` or `Provider`) is recommended for better scalability.

## Test Coverage Overview
The `test/` directory indicates a healthy testing culture with coverage across all critical layers:

-   **Unit Tests**:
    -   `services/hybrid_engine_test.dart`: Likely covers the calculation logic.
    -   `services/fare_cache_service_test.dart`: Covers local storage CRUD operations.
-   **Widget Tests**:
    -   `screens/main_screen_test.dart`, `screens/settings_screen_test.dart`, `screens/onboarding_flow_test.dart`: Ensures UI components render and interact correctly.
-   **Mocks**: `test/helpers/mocks.dart` suggests proper isolation of dependencies during testing.

## Production Readiness Verdict
**🔴 NOT READY FOR PRODUCTION**

While the core engine is solid, the application cannot be released until:
1.  **Language Selection** is implemented or the UI choice is removed.
2.  **Error States** (Network failure, API limits) are handled gracefully in the UI.
3.  **Hardcoded Logic** for transport mode comparison is refactored to be more dynamic.