# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.4.0] - 2026-01-01

### Added
- Added `TransportIconService` support for all supported Philippine transport modes.
- Added multiple icon style variants through `TransportIconStyle`.
- Added supporting documentation for the visual refresh and icon system.

### Changed
- Migrated dark mode to the Material 3 2025 surface model.
- Updated native app assets and logo configuration.

### Security
- Removed `.env` from app assets.
- Improved null safety in fare formula parsing.

## [2.3.0.1] - 2026-01-01

### Changed
- Refactored the APK release workflow for cleaner release output.
- Simplified APK naming and release generation behavior.
- Updated app icons for better consistency across devices.

### Fixed
- Removed unused imports and cleaned up release-related code paths.

## [2.3.0] - 2026-01-01

### Added
- Added complete offline mode support for fare calculation and route planning.
- Added offline map picker support and geocoding cache behavior.
- Added accuracy indicators and offline status messaging.

### Changed
- Added a four-level routing fallback strategy for online and offline use.
- Improved offline workflow test coverage and route handling consistency.

## [2.2.0] - 2026-01-01

### Added
- Added location suggestions for map and main location inputs.
- Added transport mode selection improvements and grouped mode controls.
- Added improved loading indicators and fare sorting options.

### Changed
- Improved transport mode preference persistence.
- Improved fare result formatting, route swapping behavior, and address display.

## [2.1.0] - 2025-12-15

### Added
- Added theme switching with light, dark, and system modes.
- Added theme-aware map tiles.
- Added visual branding and launcher icon improvements.

### Changed
- Improved Material 3 styling and dark mode accessibility.
- Refined offline map download UX and related visual polish.

## [2.0.0-build2-20251215125710] - 2025-12-15

### Changed
- Restructured the project after the v2.0.0 release build.
- Removed unnecessary desktop platform folders.
- Updated the README and supporting project documentation.

## [2.0.0-build2-20251215123738] - 2025-12-15

### Added
- Added modular island-based offline map downloads.
- Added expanded offline routing and region management support.

### Fixed
- Fixed offline map download issues and improved download recovery behavior.
- Fixed connectivity checks and startup stability for offline map initialization.

## [2.0.0] - 2025-12-04

### Added
- Added the Material 3 UI overhaul for the main application flows.
- Added fare grouping, passenger handling improvements, and regional filtering.
- Added release automation for Android APK publishing.

### Changed
- Rebranded the app from Fare Estimator to Pasahe.
- Expanded supported transport modes and fare calculation coverage.
