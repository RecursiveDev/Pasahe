# Codebase Analysis Report

**Date:** 2025-12-10
**Version:** 1.0.0
**Subject:** Analysis of PH Fare Calculator Codebase for Feature Planning

## 1. Executive Summary

The PH Fare Calculator is a Flutter-based application designed to estimate public transport costs in the Philippines. The current architecture follows a clean separation of concerns with a core "Hybrid Engine" handling calculation logic.

**Key Findings:**
*   **Routing:** Currently relies on the public OSRM demo server (`router.project-osrm.org`) for road-following routes, with a Haversine fallback. There is **no offline routing capability**.
*   **Maps:** Uses `flutter_map` with standard OpenStreetMap online tiles. There is **no offline map tile caching** or area download mechanism implemented.
*   **Offline Support:** "Offline" features are currently limited to viewing static reference data (fare matrices) and previously saved routes stored via Hive.
*   **Code Quality:** Generally good modularity in services, but `MainScreen` is monolithic (1600+ lines) and requires refactoring.

## 2. Architecture Overview

The project uses a layered architecture:
*   **Presentation Layer:** `lib/src/presentation/` (Screens and Widgets)
*   **Domain/Core Layer:** `lib/src/core/` (Business Logic, specifically `HybridEngine`)
*   **Data/Service Layer:** `lib/src/services/` (External APIs, Routing, Settings)

### Key Components
*   **HybridEngine (`lib/src/core/hybrid_engine.dart`):** The brain of the application. It switches between "Static" calculations (Trains/Ferries based on JSON matrices) and "Dynamic" calculations (Jeepneys/Taxis based on distance formulas).
*   **RoutingService (`lib/src/services/routing/`):** Abstract interface with two implementations:
    *   `OsrmRoutingService`: Fetches GeoJSON geometry and distance from OSRM.
    *   `HaversineRoutingService`: Calculates straight-line distance (no geometry).

## 3. Detailed Implementation Analysis

### 3.1 Routing Implementation
*   **Current State:**
    *   `OsrmRoutingService` makes HTTP GET requests to `http://router.project-osrm.org`.
    *   Parses GeoJSON coordinates for drawing polylines on the map.
    *   **Critical Issue:** The OSRM demo server is not for production use (rate limited, no SLA).
    *   **Critical Issue:** No offline fallback for routing geometry; fallback `HaversineRoutingService` only provides distance, resulting in a straight line on the map or no visual route.

### 3.2 Map Implementation
*   **Current State:**
    *   `MapPickerScreen` and `MapSelectionWidget` use `flutter_map`.
    *   Tile Layer: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
    *   **Critical Issue:** This URL requires an active internet connection. No caching strategy is visible in `pubspec.yaml` or widget configuration.

### 3.3 Offline Capabilities
*   **Current State:**
    *   **Data:** `Hive` is used to store `FareResult` objects (Saved Routes) and likely settings.
    *   **Reference:** Static JSON files (`assets/data/`) provide offline data for trains/ferries.
    *   **Missing:** Map tiles and Routing Graph are purely online. "Offline Mode" currently just means "accessing local JSONs and Hive DB".

### 3.4 Code Organization
*   **Strengths:**
    *   Dependency Injection via `get_it` and `injectable`.
    *   Clear separation of `RoutingService` interface allowing easy swapping of providers.
*   **Weaknesses:**
    *   `MainScreen.dart` is an "Anti-Pattern" God Class. It handles:
        *   UI Layout
        *   State Management (passenger counts, sorting)
        *   Orchestrating `HybridEngine` calls
        *   Handling Geocoding results
        *   Managing Bottom Sheets
    *   This makes adding new features (like offline region management) risky and difficult.

## 4. Dependencies Analysis (`pubspec.yaml`)

| Dependency | Purpose | Status |
| :--- | :--- | :--- |
| `flutter_map: ^8.2.2` | Map rendering | **Keep**. Needs offline tile provider plugin. |
| `latlong2: ^0.9.1` | Geospatial calculations | **Keep**. Standard. |
| `http: ^1.6.0` | API calls (OSRM) | **Keep**. |
| `hive: ^2.2.3` | Local Database | **Keep**. Used for saving routes. |
| `geolocator: ^13.0.2` | GPS location | **Keep**. |
| `injectable`/`get_it` | DI | **Keep**. |

**Missing Dependencies for Requested Features:**
*   A tile caching library (e.g., `flutter_map_tile_caching` or custom implementation using `dio` + file system).
*   Potentially a more robust state management solution (e.g., `flutter_bloc` or `riverpod`) to decouple logic from `MainScreen`.

## 5. Gap Analysis & Recommendations

### Goal 1: Add Road-Following Routing
*   **Gap:** Currently exists via OSRM but is fragile (demo server) and online-only.
*   **Recommendation:**
    1.  Keep OSRM for online mode but switch to a reliable provider (self-hosted or paid tier if traffic increases).
    2.  For "offline-first", full offline road routing is complex. **Alternative:** Cache the OSRM response when a route is calculated so it can be viewed offline later. True offline routing (calculating a *new* route offline) requires a graph engine (like Valhalla/GraphHopper) running on the device, which is heavy.
    *   *Refined Approach:* Focus on **caching calculated routes** first. True offline routing might be out of scope without native C++ integration.

### Goal 2: Offline-First Architecture (Downloadable Maps)
*   **Gap:** No tile download mechanism.
*   **Recommendation:**
    1.  Implement a "Region Manager" in `OfflineMenuScreen`.
    2.  Allow users to download tiles for specific bounding boxes (e.g., "Metro Manila", "Cebu").
    3.  Use a custom `TileProvider` in `flutter_map` that checks local storage first, then network.

### Goal 3: Clean/Organize Codebase
*   **Gap:** `MainScreen` is unmaintainable.
*   **Recommendation:**
    1.  **Refactor `MainScreen`:** Extract sub-widgets (e.g., `PassengerSelector`, `LocationInputCard`, `FareResultList`).
    2.  **Logic Extraction:** Move state logic (passenger counting, form validation) into a `MainViewModel` or `MainCubit` (if adopting Bloc).
    3.  **Standardize Repository Pattern:** Ensure all data access (even OSRM) goes through a Repository, not just Services called directly by widgets.

## 6. Implementation Plan (Proposed)

1.  **Refactor Phase:** Break down `MainScreen` to prepare for new UI elements.
2.  **Map Infrastructure:** Implement the custom offline `TileProvider`.
3.  **Download Manager:** Create the UI and logic for downloading map regions.
4.  **Routing Hardening:** Improve `OsrmRoutingService` error handling and implement response caching.