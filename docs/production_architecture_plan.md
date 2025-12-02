# Production Readiness Architecture Plan

## Executive Summary
This document outlines the technical roadmap to elevate the **PH Fare Calculator** from a functional Beta to a robust, production-ready application. The current codebase demonstrates solid core logic but suffers from scalability issues (manual service instantiation), lack of localization, and brittle error handling. This plan introduces a formal Dependency Injection container, a standard Internationalization (i18n) pipeline, a comprehensive Error Handling strategy, and a dynamic Recommendation Engine to replace hardcoded comparisons. These changes will ensure the app is maintainable, user-friendly, and ready for public release.

---

## 1. Dependency Injection (DI) Strategy
**Current State**: Services are instantiated manually in `main.dart` or lazily within `initState` of widgets. This makes unit testing difficult and tightens coupling.
**Target Architecture**: Use **`get_it`** as a Service Locator and **`injectable`** for compile-time dependency generation.

### Implementation Details
1.  **Libraries**:
    -   `get_it`: ^7.6.0
    -   `injectable`: ^2.3.0
    -   `injectable_generator`: ^2.4.0 (dev)
    -   `build_runner`: (existing)

2.  **Service Lifetime**:
    -   `@Singleton`: `SettingsService`, `FareCacheService`, `RemoteConfigService` (Stateful, app-wide).
    -   `@LazySingleton`: `GeocodingService`, `OsrmRoutingService`, `HybridEngine` (Stateless mostly, expensive to init).

3.  **Migration Plan**:
    -   Create `lib/src/core/di/injection.dart` to handle `GetIt` initialization.
    -   Annotate existing services with `@injectable` or `@singleton`.
    -   Refactor `main.dart` to call `configureDependencies()` before `runApp`.
    -   Remove constructor injection in `MainScreen` and replace with `GetIt.I<Service>()` (or `inject` hook if using a stacked architecture, but `GetIt.I` is sufficient for now).

---

## 2. Localization & Internationalization
**Current State**: Hardcoded English strings. Empty handlers for language selection.
**Target Architecture**: Native Flutter localization using **`flutter_localizations`** and **`.arb` files**.

### Implementation Details
1.  **Configuration**:
    -   Add `flutter_localizations` to `dependencies`.
    -   Create `l10n.yaml` in project root:
        ```yaml
        arb-dir: lib/src/l10n/arb
        template-arb-file: app_en.arb
        output-localization-file: app_localizations.dart
        ```
2.  **File Structure**:
    -   `lib/src/l10n/arb/app_en.arb`: English (Source).
    -   `lib/src/l10n/arb/app_tl.arb`: Tagalog.

3.  **Usage**:
    -   Replace strings like `'Calculate Fare'` with `AppLocalizations.of(context)!.calculateFare`.
    -   Implement `LocaleProvider` (using `SettingsService`) to toggle `MaterialApp.locale` dynamically without restarting.

---

## 3. Error Handling Strategy
**Current State**: Silent failures (empty lists) or console logs. No user feedback.
**Target Architecture**: **Typed Exceptions** and a Centralized **UI Feedback Mechanism**.

### 3.1 Custom Exceptions
Create `lib/src/core/errors/failures.dart`:
-   `NetworkFailure`: No internet connection.
-   `ServerFailure`: 500 errors or invalid API keys.
-   `LocationNotFoundFailure`: Geocoding returned 0 results.
-   `ConfigSyncFailure`: Remote Config fetch failed.

### 3.2 Service Layer Refactoring
Refactor services to throw these specific exceptions instead of generic ones or returning empty data.
*Example (`GeocodingService`)*:
```dart
try {
  // api call
} catch (e) {
  throw NetworkFailure('Please check your internet connection.');
}
```

### 3.3 UI Feedback (The "ErrorHandler" Mixin)
Create a mixin or helper class `ErrorDisplayHelper` to standardize how errors are shown.
-   **Critical Errors** (Blocking): Show `AlertDialog`.
-   **Transient Errors** (Background sync): Show `SnackBar` with Retry button.
-   **Input Errors**: Show `InputDecoration.errorText`.

---

## 4. Dynamic Comparison & Recommendation Engine
**Current State**: `MainScreen` hardcodes comparison to specifically "Jeepney (Traditional)" and "Taxi (White)".
**Target Architecture**: A **`FareComparisonService`** that intelligently selects modes.

### Logic Flow
1.  **Fetch All Formulas**: Retrieve all available formulas from `FareCacheService`.
2.  **Filter by Applicability**:
    -   *Distance Heuristics*:
        -   If `distance > 300km`: Exclude Tricycle/Jeepney? (Maybe warn instead).
        -   If `distance < 1km`: Suggest Walking?
    -   *Location Heuristics*:
        -   If `origin` is "NAIA" or "Airport": Prioritize "Yellow Taxi".
        -   If `provincialMode` is ON: Prioritize Bus/Jeep.
3.  **Sort/Rank**:
    -   Sort by `estimatedCost` (Cheapest first).
    -   Or group by `Luxury` vs `Economy`.

### Implementation
-   Create `lib/src/services/recommendation/fare_comparison_service.dart`.
-   Method: `List<FareResult> compareModes(Location origin, Location dest, double distanceKm)`.
-   Updates `MainScreen` to consume this service instead of manual loop.

---

## 5. Data Persistence & Synchronization
**Current State**: `RemoteConfig` is fetched but sync logic to Hive is opaque. `FareCacheService` manually seeds defaults.
**Target Architecture**: **Config-First, Offline-Capable**.

### Data Flow
1.  **Boot**: App starts.
2.  **Hydrate**: `FareCacheService` loads formulas from **Hive** immediately (Zero latency).
3.  **Background Sync**:
    -   `RemoteConfigService` fetches new values.
    -   **Validation**: Check if `version` in Remote Config > `version` in Hive.
    -   **Update**: If newer, parse JSON -> `FareFormula` objects -> Put to Hive.
4.  **Hot Reload**: Use a `ValueNotifier` or `Stream` in `FareCacheService` so the UI updates instantly if configs change while the app is open.

### Artifacts
-   Update `FareFormula.fromJson` to handle RemoteConfig's flexible structure.
-   Update `RemoteConfigService` to explicitly call `FareCacheService.saveFormulas()` upon successful fetch.

---

## 6. Implementation Roadmap

### Phase 1: Foundation (Days 1-2)
-   [ ] Install `get_it`, `injectable`, `flutter_localizations`.
-   [ ] Set up DI container `injection.dart`.
-   [ ] Create ARB files and `l10n.yaml`.

### Phase 2: Refactoring Core (Days 2-3)
-   [ ] Migrate `SettingsService`, `GeocodingService`, `RoutingService` to DI.
-   [ ] Implement `FareComparisonService` logic.
-   [ ] Refactor `MainScreen` to use `FareComparisonService`.

### Phase 3: Resilience & Polish (Days 4-5)
-   [ ] Implement Custom Exception classes.
-   [ ] Add `try/catch` blocks with `ErrorDisplayHelper` in `MainScreen`.
-   [ ] Connect `RemoteConfig` -> `Hive` sync logic.
-   [ ] Verify "Language Select" in Onboarding works.

### Phase 4: Final Verification
-   [ ] Run full regression suite.
-   [ ] Test Offline Mode (Airplane mode).
-   [ ] Test "Bad Network" handling.
