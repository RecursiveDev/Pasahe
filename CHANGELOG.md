# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.0+1] - 2025-01-01

### Added
- **Full Offline Mode Implementation**: The app can now function completely without an internet connection.
- **Offline Map Regions**: Download specific regions (Luzon, Visayas, Mindanao) for offline map viewing.
- **Hybrid Routing Fallback**: Automatic switching to Haversine (point-to-point) routing when OSRM is unavailable or offline.
- **Geocoding Cache**: Persistent storage for recently searched locations.
- **Offline Fare Calculation**: All road formulas and rail/ferry matrices are available offline.
- **Smart Connectivity Detection**: Real-time monitoring of network status with automatic UI adjustments.
- **Offline UI Indicators**: Visual cues showing when the app is in offline mode and which features are limited.
- **Auto-Caching Strategy**: Intelligent background caching of map tiles for recently viewed areas.

### Changed
- Improved `HybridEngine` to handle offline state seamlessly.
- Updated `SettingsScreen` with offline management options.

## [2.2.0+4] - 2024-12-15
- Initial beta release with core fare calculation logic.
- Road formula support for Jeeps, Buses, Taxis.
- Static matrix support for LRT/MRT.
