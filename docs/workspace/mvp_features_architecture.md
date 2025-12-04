# MVP Features Architecture & Implementation Plan

**Date:** December 4, 2025
**Status:** Architecture Design Complete

## Executive Summary
This document outlines the technical design for the three remaining MVP features: Dynamic Map Adjustment, Regional Transport Filtering, and Fare Grouping. The design leverages the existing `HybridEngine` and `FareComparisonService`, introducing a new `TransportModeFilterService` to handle regional availability logic based on the research findings.

## 1. Regional Transport Filtering

### Design Strategy
We implement a "Region-First" approach where the user's selected location determines the available transport modes. This prevents invalid options (e.g., "EDSA Carousel" in Cebu) from appearing.

### 1.1 New Artifacts

#### A. Region Constants (`lib/src/core/constants/region_constants.dart`)
Defines the geographical boundaries for key supported regions.
*   **NCR (Metro Manila)**: Defined by a bounding box covering the greater capital region.
*   **Cebu (Metro Cebu)**: Bounding box covering Cebu City, Mandaue, Lapu-Lapu.
*   **Davao (Metro Davao)**: Bounding box for Davao City.
*   **CDO (Cagayan de Oro)**: Bounding box for CDO.

**Implementation Logic:**
Simple `LatLngBounds.contains(point)` checks are used for MVP. While polygons are more accurate, bounding boxes are sufficient for the major urban centers prioritized in the MVP.

#### B. Region Configuration (`lib/src/models/region_config.dart`)
A static mapping configuration that links `TransportMode` enums to `Region` enums.
*   **Source:** `docs/workspace/transport_availability_research.md`
*   **Structure:** `Map<TransportMode, List<Region>>`
*   **Default:** Modes like Jeepney, Tricycle, and Buses are available `Region.nationwide`.

#### C. Filter Service (`lib/src/services/transport_mode_filter_service.dart`)
A centralized service responsible for:
1.  **Geocoding to Region:** Converting a `lat/lng` pair into a `Region` enum.
2.  **Filtering:** Returning a list of `TransportMode`s valid for a specific location.

**Usage in `MainScreen`:**
When `_calculateFare` is triggered, the app will first query this service:
```dart
final validModes = _filterService.getAvailableModes(origin.lat, origin.lng);
// Pass validModes to HybridEngine or filter results afterwards
```

## 2. Dynamic Map Adjustment

### Design Strategy
The map must provide visual feedback that feels responsive but not disorienting.

### 2.1 Logic & Controller Methods
*   **Controller:** `flutter_map`'s `MapController`.
*   **Methods:**
    *   `move(LatLng center, double zoom)`: Used when a single point (Origin) is selected.
    *   `fitCamera(CameraFit.bounds(...))`: Used when both Origin and Destination are set.

### 2.2 Behavior Rules
1.  **Origin Selected Only:**
    *   **Action:** Pan the camera to center on the Origin.
    *   **Zoom:** Maintain current zoom unless it's too far out (e.g., < 10), then zoom in to ~13.
2.  **Origin & Destination Selected:**
    *   **Action:** Fit the camera bounds to include both points.
    *   **Padding:** Apply `EdgeInsets.all(50)` to ensure markers aren't on the screen edge.

### 2.3 Implementation in `MapSelectionWidget`
The existing `didUpdateWidget` method correctly monitors changes. We will formalize this to ensure:
*   Use `LatLngBounds` to encapsulate both points.
*   Trigger `fitCamera` with `CameraFit.bounds` when the second point is added.

## 3. Fare Grouping

### Design Strategy
Instead of a flat list, fares should be grouped by their mode (e.g., all "Bus" options together) to reduce cognitive load.

### 3.1 Data Model Changes
No changes to `FareResult` are needed. The grouping happens at the *presentation* or *service* level.

### 3.2 Service Logic (`FareComparisonService`)
A new method `groupFaresByMode` transforms the flat list:
```dart
Map<TransportMode, List<FareResult>> groupFaresByMode(List<FareResult> results);
```

### 3.3 UI Structure
The `MainScreen` will iterate through the grouped keys:
```dart
ListView(
  children: groupedResults.entries.map((entry) {
    return Column(
      children: [
        SectionHeader(mode: entry.key), // e.g. "Jeepney"
        ...entry.value.map((fare) => FareResultCard(fare: fare)),
      ],
    );
  }).toList(),
)
```

## 4. Source Code Artifacts Created/Updated

### `lib/src/core/constants/region_constants.dart`
```dart
class RegionConstants {
  static final LatLngBounds ncrBounds = LatLngBounds(...);
  // ... other bounds
}
```

### `lib/src/models/region_config.dart`
```dart
class RegionConfig {
  static final Map<TransportMode, List<Region>> modeAvailability = {
    TransportMode.train: [Region.ncr, Region.luzon],
    // ...
  };
}
```

### `lib/src/services/transport_mode_filter_service.dart`
```dart
class TransportModeFilterService {
  Region getRegionForLocation(double lat, double lng) { ... }
  List<TransportMode> getAvailableModes(double lat, double lng) { ... }
}
```

### `lib/src/services/fare_comparison_service.dart`
*   Added `groupFaresByMode` method.

## 5. Verification Plan
1.  **Region Detection:** Unit test `getRegionForLocation` with known coordinates (e.g., Luneta Park -> NCR, Magellan's Cross -> Cebu).
2.  **Filtering:** Verify that `TransportMode.train` is NOT returned for a Cebu coordinate.
3.  **Grouping:** Verify that a mixed list of Jeepney and Bus fares results in a Map with 2 keys.