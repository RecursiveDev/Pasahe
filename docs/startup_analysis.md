# Startup Analysis & Black Screen Investigation

## Issue Description
Users on certain devices (specifically Huawei/non-GMS) experience a "black screen" on startup. This is a common symptom when an application awaits a Future that never completes or hangs due to missing platform dependencies (like Google Play Services) before calling `runApp()`.

## Root Cause Analysis

### 1. Blocking Firebase Initialization
In `lib/main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```
**Problem**: On devices without Google Play Services (e.g., Huawei, custom ROMs), `Firebase.initializeApp` may hang indefinitely or take a very long time to timeout if the underlying Google Play Services are missing or malfunctioning. Since this `await` call happens *before* `runApp()`, the Flutter engine has initialized but no widget tree is attached, resulting in a black screen.

### 2. Remote Config Fetching
In `lib/main.dart`:
```dart
await getIt<RemoteConfigService>().initialize();
```
In `RemoteConfigService.initialize()`:
```dart
final updated = await _remoteConfig.fetchAndActivate();
```
**Problem**: This performs a synchronous network call during the splash phase (or technically *before* the splash phase, as it's in `main()`). If the network is slow, blocked, or if Firebase initialization failed silently, this call will block the UI from rendering anything. The app will appear frozen on a black screen until the network request times out.

## Recommended Fixes

### 1. Remove Firebase Dependencies (Primary Solution)
Since the goal of this project is to remove cloud dependencies, removing `Firebase.initializeApp` and `RemoteConfigService` entirely will inherently solve this issue.

### 2. Move Initialization Logic (Architectural Best Practice)
Even for local initialization (like Hive), heavyweight operations should not block `runApp()`.
*   **Current**: `await init` -> `runApp()`
*   **Recommended**: `runApp(MyApp)` -> `SplashScreen` -> `init()` in background -> Navigate to Home.

**Revised Flow**:
1.  `main()` only initializes minimal bindings (`WidgetsFlutterBinding`, `dotenv`) and runs `runApp(MyApp)`.
2.  `MyApp` shows `SplashScreen` immediately.
3.  `SplashScreen` triggers initialization logic (DI, Database, Repositories) in `initState` or via a provider/bloc.
4.  Once initialization is complete, `SplashScreen` navigates to `Onboarding` or `MainScreen`.

This ensures the user *always* sees a UI (the splash logo) immediately, even if initialization takes time or fails.