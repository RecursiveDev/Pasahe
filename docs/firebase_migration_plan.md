# Firebase Migration & Local-First Architecture Plan

## Executive Summary
This document outlines the strategy to remove all Firebase and cloud dependencies from the `ph-fare-estimator` application, transitioning it to a fully local, privacy-centric architecture. The current implementation relies on Firebase Remote Config for fare formulas and Firebase Analytics/Core for telemetry. These will be replaced by local JSON assets and Hive-based local storage.

## 1. Dependency Audit

### Current Dependencies (to be removed)
| Package | Usage | Replacement Strategy |
| :--- | :--- | :--- |
| `firebase_core` | Initialization in `main.dart` | Remove entirely |
| `firebase_remote_config` | Fetching fare formulas | Load from `assets/data/fare_formulas.json` + Hive override |
| `firebase_analytics` | Tracking usage | Remove entirely (privacy first) |
| `flutter_dotenv` | API Keys for Firebase | Remove entirely if no other API keys exist |

### Impacted Files
*   `pubspec.yaml`: Remove dependency entries.
*   `lib/firebase_options.dart`: Delete file.
*   `lib/main.dart`: Remove `Firebase.initializeApp`, `RemoteConfigService` initialization, and `dotenv` loading (if unused).
*   `lib/src/services/remote_config_service.dart`: Delete file.
*   `lib/src/services/fare_cache_service.dart`: Refactor into `FareRepository`.

## 2. Local Architecture Design

### Data Storage Strategy
The app already uses **Hive** for local caching. We will elevate Hive from a "cache" to the **primary source of truth**, seeded by local JSON assets.

*   **Primary Database**: `Hive` (NoSQL, fast, key-value).
*   **Seed Data**: `assets/data/fare_formulas.json` (Source of truth for default values).
*   **User Overrides**: User-modified formulas will be saved directly to Hive, which persists across app restarts.

### Data Flow
1.  **App Start**: Check if Hive box `fareFormulas` is empty.
2.  **Seeding (if empty)**: Read `assets/data/fare_formulas.json` -> Parse -> Save to Hive.
3.  **Runtime**: The app reads/writes solely to Hive via `FareRepository`.
4.  **Updates**: Future app updates can update the JSON asset. A version flag in `SharedPreferences` or Hive can trigger a re-seed if the asset version is newer than the cached version.

### Repository Pattern Update
*   **Rename**: `FareCacheService` -> `FareRepository`.
*   **Responsibilities**:
    *   Initialize Hive boxes.
    *   Seed default data from JSON assets.
    *   Provide CRUD operations for Fare Formulas.
    *   Provide CRUD operations for Saved Routes.

## 3. Migration Steps (Execution Plan)

### Phase 1: Clean Up & Preparation
1.  **Remove Dependencies**: Run `flutter pub remove firebase_core firebase_remote_config firebase_analytics`.
2.  **Delete Configs**: Delete `lib/firebase_options.dart` and `android/app/google-services.json` (if exists), `ios/Runner/GoogleService-Info.plist` (if exists).

### Phase 2: Refactoring Data Layer
3.  **Create `FareRepository`**:
    *   Create `lib/src/repositories/fare_repository.dart`.
    *   Port logic from `FareCacheService`.
    *   Add logic to read `assets/data/fare_formulas.json` during seeding.
4.  **Delete Obsolete Services**:
    *   Delete `lib/src/services/remote_config_service.dart`.
    *   Delete `lib/src/services/fare_cache_service.dart`.

### Phase 3: Application Entry Point (`main.dart`)
5.  **Remove Initialization**: Remove `Firebase.initializeApp()` and `RemoteConfigService.initialize()`.
6.  **Inject Repository**: Register `FareRepository` in `lib/src/core/di/injection.dart` (or manually in main if using simple DI).
7.  **Initialize Repository**: Call `fareRepository.initialize()` in `main.dart` which handles the JSON seeding.

### Phase 4: UI Updates
8.  **Update References**: Find all usages of `FareCacheService` and `RemoteConfigService` in the UI and replace them with `FareRepository`.

## 4. Verification
*   App runs offline (Airplane mode).
*   No network requests on startup.
*   "Black screen" issue resolved (verified via Startup Analysis).
*   Fare formulas load correctly from assets.