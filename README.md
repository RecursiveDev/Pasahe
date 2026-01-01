# PH Fare Calculator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-blue.svg)](https://flutter.dev/)
[![CI](https://github.com/MasuRii/ph-fare-calculator/actions/workflows/ci.yml/badge.svg)](https://github.com/MasuRii/ph-fare-calculator/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-2.4.0-blue.svg)](https://github.com/MasuRii/ph-fare-calculator/releases)

**PH Fare Calculator** is a cross-platform mobile application designed to help tourists, expats, and locals estimate public transport costs across the Philippines.

## 📱 Offline Mode Features

The application now supports comprehensive offline functionality, ensuring you can calculate fares even in remote areas without internet coverage:

- **Regional Map Downloads**: Download vector-based map tiles for Luzon, Visayas, or Mindanao.
- **Persistent Geocoding**: Previously searched locations are cached locally using Hive for instant retrieval offline.
- **Smart Fallback Routing**: When internet is lost, the app automatically switches from OSRM (Road Distance) to Haversine (Direct Distance) routing to provide fare estimates.
- **Static Matrix Access**: Train (MRT/LRT) and Ferry fare matrices are bundled with the app, ensuring 100% availability.
- **Background Caching**: Intelligent caching of map tiles as you browse, making recently viewed areas available offline automatically.
- **Connectivity Awareness**: Real-time detection of 4G/5G/WiFi status with automatic mode switching.


Unlike city-centric navigation apps, this tool focuses on **"How much?"** rather than "How to?". It solves the complex problem of Philippine geography by combining distance-based formulas (for roads) with static fare matrices (for trains and ferries).

## 🚀 Key Features

- **Nationwide Coverage:** Works in Metro Manila, Cebu, Davao, and rural provinces.
- **Modular Offline Maps:** Download maps by island group (Luzon, Visayas, Mindanao) to save storage space while ensuring functionality without internet.
- **Material 3 Design:** A completely redesigned UI/UX that follows modern Material Design guidelines for better accessibility and aesthetics.
- **Dark Mode (2025 M3 Standards):** Full dark mode implementation using Material Design 3 #121212 baseline with 7-layer surface container system for optimal eye comfort and accessibility.
- **Transport Icon Service:** Unique icons for all 12 Philippine transport modes (Jeepney, Bus, Taxi, Train, Ferry, Tricycle, UV Express, Van, Motorcycle, EDSA Carousel, Pedicab, Kuliglig) with TransportIconStyle enum supporting 4 variants (filled, rounded, outlined, sharp).
- **Hybrid Calculation Engine:**
  - **Dynamic:** Uses **OSRM (Open Source Routing Machine)** to calculate road distance for Jeeps, Taxis, Buses, and Tricycles.
  - **Static:** Uses embedded Lookup Tables for fixed-price modes like MRT/LRT (Trains) and Ferries.
- **"Fair Price" Indicator:** Provides a visual "Traffic Level" and price classification (Standard, Peak, Tourist Trap) to help users gauge reasonable fares.
- **Multi-Mode Support:**
  - **Road:** Jeepney (Traditional/Modern), Bus (Ordinary/Aircon), Taxi, UV Express, Tricycle, Pedicab.
  - **Rail:** LRT-1, LRT-2, MRT-3, PNR.
  - **Water:** Ferries.
- **Smart Filtering:** "Provincial" mode toggle that adjusts fare calculation logic (e.g., 20% variance for provincial routes).
- **Offline Reference:** View saved routes and static fare matrices (Cheat Sheets) without an internet connection using **Hive** local storage.
- **Discount Support:** Built-in support for Student, Senior Citizen, and PWD discounts (20% off).

## 📋 Recent Changes (v2.4.0)

This release focuses on documentation improvements and security hardening to achieve A+ documentation assessment standards.

### Visual Improvements
- **Dark Mode Migration to 2025 M3 Standards:** Implemented Material Design 3 dark theme with #121212 baseline color, replacing the previous dark cyan theme for better eye comfort and accessibility compliance.
- **7-Layer Surface Container System:** Added comprehensive surface hierarchy with surfaceContainerLowest through surfaceBright roles for improved visual depth and accessibility.
- **Transport Icon Service:** Created centralized `TransportIconService` providing unique icons for all 12 Philippine transport modes:
  - Jeepney, Bus (Ordinary/Aircon), Taxi, Train, Ferry, Tricycle, UV Express, Van, Motorcycle, EDSA Carousel, Pedicab, Kuliglig
  - `TransportIconStyle` enum with 4 variants: filled, rounded, outlined, sharp
  - Accessibility-friendly semantic labels for all icons

### Security Enhancements
- **Environment Configuration:** Removed `.env` file from assets directory to eliminate any potential exposure risk in production builds.
- **Null Safety:** Implemented comprehensive null safety patterns in fare formula parsing to prevent runtime exceptions.
- **Security Audit:** Completed comprehensive security audit documenting findings and remediation steps.

### Documentation Updates
- Created `docs/security/SECURITY_AUDIT_2026-01-01.md` with executive summary, findings, and remediation status
- Updated `docs/architecture/TRANSPORT_ICONS_DESIGN.md` with complete API design for icon service
- Added dark mode research documentation in `docs/research/mobile-dark-mode-standards-2025-01-01.md`

## 🛠 Tech Stack

- **Framework:** Flutter & Dart
- **State Management & DI:** `injectable` + `get_it` for dependency injection.
- **Routing:** **OSRM** (Open Source Routing Machine) for road distances.
- **Geocoding:** **OpenStreetMap (Nominatim)** via `http` for place search and reverse geocoding.
- **Offline Maps:** `flutter_map_tile_caching` for downloading and storing map regions.
- **Connectivity:** `connectivity_plus` for smart online/offline network detection.
- **Local Storage:** `hive` for persisting saved routes and `shared_preferences` for user settings.
- **Maps:** `flutter_map` with `latlong2`.

## 🧮 How It Works (The Hybrid Engine)

The Philippines has a fragmented transport pricing system. This app handles it using two methods via the `HybridEngine`:

### 1. Formula-Based (Road)
Used for **Jeepneys, Buses, Taxis, UV Express, Tricycles**.
> `Fare = Base Fare + ((OSRM Distance * 1.15) * Per KM Rate)`

*   **Why 1.15?** Public transport routes are rarely as direct as private car routes. We add a 15% variance factor to OSRM's output to approximate real-world travel conditions and deviations.
*   **Provincial Variance:** A 20% multiplier is applied to specific modes (like Jeepneys) when the "Provincial" toggle is enabled in settings.

### 2. Matrix-Based (Fixed)
Used for **MRT, LRT, PNR, and Ferries**.
Distance formulas fail here (e.g., Rail distance ≠ Road distance).
> `Fare = Database lookup [Origin_Station] -> [Dest_Station]`

## 📂 Project Structure

```
lib/
├── src/
│   ├── core/               # Core logic (HybridEngine, DI, Errors, Theme)
│   ├── models/             # Data models (FareResult, Location, MapRegion, etc.)
│   ├── presentation/       # Flutter UI (Material 3)
│   │   ├── controllers/    # State management controllers
│   │   ├── screens/        # MainScreen, Settings, RegionDownload, etc.
│   │   └── widgets/        # Reusable components
│   ├── repositories/       # Data access layers (Fare, Region)
│   ├── services/           # External services
│   │   ├── connectivity/   # Network status detection
│   │   ├── geocoding/      # OpenStreetMap/Nominatim implementation
│   │   ├── offline/        # Offline map management
│   │   └── routing/        # OSRM & Haversine routing services
│   └── l10n/               # Localization (English/Tagalog)
└── main.dart
```

## ⚙️ Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone https://github.com/MasuRii/ph-fare-calculator.git
    cd ph-fare-calculator
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the Code Generator**
    This project uses `build_runner` for JSON serialization and Dependency Injection.
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the App**
    ```bash
    flutter run
    ```

## ⚠️ Disclaimer

This app provides **estimates only**. Official fares are regulated by the LTFRB/DOTr and are subject to change without notice. This app is not affiliated with any government agency. The "Tourist Trap" indicator is an estimate based on high-traffic pricing models and does not constitute a legal accusation.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Built with ❤️ for Philippine Commuters.*