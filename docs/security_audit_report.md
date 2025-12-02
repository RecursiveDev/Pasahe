# Security & Privacy Audit Report

**Date:** 2025-12-02
**Auditor:** Security Reviewer Mode
**Subject:** `ph-fare-estimator` Codebase

## 1. Executive Summary
The application has made significant progress in moving away from Firebase, but **critical security artifacts remain** in the codebase. Active API keys and configuration files were found in the source tree. Furthermore, while the database is local, the routing engine (`OsrmRoutingService`) still relies on a public external API, which may violate the strict "offline/privacy" requirement by sending user location data over the network.

## 2. Findings Summary

| ID | Severity | Category | Description | File(s) |
| :--- | :--- | :--- | :--- | :--- |
| **SEC-01** | **CRITICAL** | Secrets | Active Firebase/Google API Keys exposed. | `ios/Runner/GoogleService-Info.plist`<br>`android/app/google-services.json`<br>`build/unit_test_assets/.env` |
| **SEC-02** | **HIGH** | Privacy | "No Online" violation: User location sent to public OSRM API. | `lib/src/services/routing/osrm_routing_service.dart` |
| **SEC-03** | **MEDIUM** | Data Security | User location history (Saved Routes) stored without encryption. | `lib/src/repositories/fare_repository.dart` |
| **SEC-04** | **LOW** | Cleanup | Residual build artifacts from Firebase Analytics. | `build/` directory (requires clean) |

## 3. Detailed Findings

### SEC-01: Residual Cloud Secrets (Critical)
**Observation:**
The following files contain API keys (`AIza...`) and project identifiers:
*   `ios/Runner/GoogleService-Info.plist`: Contains `API_KEY`, `GCM_SENDER_ID`, `STORAGE_BUCKET`.
*   `android/app/google-services.json`: Presence confirmed.
*   `build/unit_test_assets/.env`: Contains `FIREBASE_ANDROID_API_KEY`, `FIREBASE_IOS_API_KEY`, etc.

**Risk:**
Even if the project is migrating away, these keys can be scraped if the repo is public, potentially leading to quota theft or unauthorized access to the old project.

**Recommendation:**
1.  **Delete** `ios/Runner/GoogleService-Info.plist`.
2.  **Delete** `android/app/google-services.json`.
3.  **Delete** `build/` directory (run `flutter clean`).
4.  **Rotate** the keys in the Google Cloud Console if they were ever public.

### SEC-02: OSRM Online Dependency (High)
**Observation:**
`OsrmRoutingService` performs an HTTP GET request to `http://router.project-osrm.org`.
```dart
final requestUrl = '$_baseUrl/$originLng,$originLat;$destLng,$destLat?overview=false';
```

**Risk:**
*   **Privacy**: User's start and end coordinates are sent to a third-party server.
*   **Availability**: The app requires internet for this feature, contradicting the "fully local" goal.

**Recommendation:**
*   **Immediate**: Flag this to the user. If "Offline" is a hard requirement, this feature must be replaced with a simple Haversine distance calculation (lower accuracy, 100% offline) or an offline routing engine (complex integration).
*   **Mitigation**: If OSRM is kept, add a disclaimer to the user that routing requires internet, or fallback to Haversine when offline.

### SEC-03: Unencrypted Local Storage (Medium)
**Observation:**
`FareRepository` uses Hive to store `SavedRoute` objects.
```dart
Future<Box<SavedRoute>> openSavedRoutesBox() async {
  return await Hive.openBox<SavedRoute>(_savedRoutesBoxName); // No encryption cipher
}
```

**Risk:**
On a rooted/jailbroken device, or via backup extraction, an attacker could read the user's travel history (Home/Work locations).

**Recommendation:**
Implement Hive encryption using `HiveAesCipher` and store the key securely (e.g., using `flutter_secure_storage`).
*Note: For `FareFormula` (static data), encryption is not necessary.*

### SEC-04: Build Artifacts (Low)
**Observation:**
The `build/` directory contains generated manifests and logs referencing `firebase_analytics`, even though it was removed from `pubspec.yaml`.

**Recommendation:**
Run `flutter clean` to remove stale artifacts.

## 4. Conclusion
The codebase is **not yet production-ready** from a security standpoint due to the presence of secrets and the privacy implication of the OSRM service. Remediation of SEC-01 is required immediately. SEC-02 requires a product decision on the trade-off between routing accuracy and privacy.