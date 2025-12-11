# Current Offline Map Architecture

## Executive Summary
The current offline map system enables users to download map tiles for offline usage, backed by `flutter_map_tile_caching` (FMTC) for tile management and `Hive` for metadata persistence. 

**Critical Finding**: The application currently relies entirely on **hardcoded regions** defined in `lib/src/models/map_region.dart` (Luzon, Visayas, Mindanao). The file `assets/data/regions.json` exists but appears to be **unused** in the current codebase and defines completely different regions (Metro Manila, Cebu Metro, Davao City) with a different schema.

## Data Structures

### 1. MapRegion Model (Dart)
**File**: `lib/src/models/map_region.dart`

The core data model used by the application. It extends `HiveObject` for local persistence.

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier (e.g., 'luzon'). |
| `name` | `String` | Display name. |
| `description` | `String` | Short description. |
| `southWestLat/Lng` | `double` | Coordinates for the South-West corner of the bounding box. |
| `northEastLat/Lng` | `double` | Coordinates for the North-East corner of the bounding box. |
| `minZoom/maxZoom` | `int` | Zoom levels to download (default 10-16 in JSON / 8-14 in Dart). |
| `status` | `DownloadStatus` | Enum: `notDownloaded`, `downloading`, `downloaded`, etc. |
| `estimatedSizeMB` | `int` | Pre-calculated size estimate. |

**Hardcoded Regions (`PredefinedRegions` class)**:
The app currently supports exactly three regions, hardcoded in Dart:
*   **Luzon**: (SW: 7.5, 116.9) to (NE: 21.2, 124.6)
*   **Visayas**: (SW: 9.0, 121.0) to (NE: 13.0, 126.2)
*   **Mindanao**: (SW: 4.5, 119.0) to (NE: 10.7, 127.0)

### 2. Unused Region Configuration (JSON)
**File**: `assets/data/regions.json`

This file defines a different schema and set of regions (cities vs islands). It is likely a template for future dynamic loading or a leftover artifact.

**Schema**:
```json
[
  {
    "id": "metro_manila",
    "name": "Metro Manila",
    "description": "...",
    "bounds": {
      "north": 14.75,
      "south": 14.35,
      "east": 121.15,
      "west": 120.90
    },
    "estimatedSize": "150 MB",
    "zoomLevels": {
      "min": 10,
      "max": 16
    }
  }
]
```

**Key Differences**:
*   JSON uses `bounds` object with `north/south/east/west`.
*   Dart uses flat `southWestLat`, `southWestLng`, `northEastLat`, `northEastLng`.
*   JSON defines City-level data; Dart defines Island-Group level data.

## Offline Map Service
**File**: `lib/src/services/offline/offline_map_service.dart`

This service manages the lifecycle of map downloads using the `flutter_map_tile_caching` library.

### Core Workflows
1.  **Initialization**:
    *   Initializes FMTC backend.
    *   Opens a Hive box `offline_maps` to store `MapRegion` objects.
    *   **Restoration**: It iterates through the hardcoded `PredefinedRegions.all` and attempts to restore their status/progress from the Hive box. *This confirms the dependency on hardcoded regions.*

2.  **Download Process**:
    *   Converts `MapRegion` bounds to `fmtc.RectangleRegion`.
    *   Starts a foreground download via `store!.download.startForeground`.
    *   Updates the `MapRegion` object (status, progress) in real-time and persists changes to Hive.

3.  **Tile Serving**:
    *   Provides a `TileLayer` via `getCachedTileLayer()` that reads from the FMTC store.
    *   `isPointCached(LatLng point)` checks if a coordinate falls within any `downloaded` region in `PredefinedRegions.all`.

## UI Integration
**File**: `lib/src/presentation/screens/region_download_screen.dart`

*   **Data Source**: Directly iterates over `PredefinedRegions.all` to build the list of cards.
*   **State Management**: Uses `setState` and listens to `OfflineMapService.progressStream`.
*   **Actions**:
    *   `downloadRegion`: Triggers service download.
    *   `deleteRegion`: Calls service delete (which marks status as `notDownloaded` in Hive).

## Recommendations for Modular Island Structure

To support the goal of modular offline map downloads (Islands within Regions), the following architecture changes are required:

1.  **Adopt a Hierarchical Data Model**:
    *   Refactor `MapRegion` to support parent-child relationships or categories (e.g., `parentId` or `type: "island" | "region"`).
    *   Or, replace the flat `PredefinedRegions` list with a structure that groups Islands under the main Regions (Luzon, Visayas, Mindanao).

2.  **Operationalize `regions.json`**:
    *   Stop using hardcoded `PredefinedRegions`.
    *   Update `regions.json` to include the specific islands needed (e.g., Palawan, Negros, Panay) with their specific bounding boxes.
    *   Implement a `RegionRepository` that parses `regions.json` at startup.

3.  **Update Bounding Box Logic**:
    *   The Service currently downloads rectangular bounds. Islands are often irregular.
    *   *Note*: FMTC supports `PolygonRegion` in addition to `RectangleRegion`. For complex islands, moving to Polygon definitions in the JSON (list of coordinates) would save significant storage space compared to large bounding boxes that include water.

4.  **Migration Strategy**:
    *   Create a new `assets/data/island_regions.json` (or update existing) with the target hierarchy.
    *   Update `MapRegion.fromMap()` to parse this JSON.
    *   Update `OfflineMapService` to initialize from this loaded data instead of static classes.