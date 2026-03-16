<p align="center">
  <img src="assets/icons/PasaheLogo/icon-192x192.png" alt="Pasahe logo" width="120" />
</p>

<h1 align="center">Pasahe</h1>

<p align="center">A Flutter app for estimating public transport fares across the Philippines.</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow.svg" alt="MIT License" /></a>
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/flutter-stable-blue.svg" alt="Flutter" /></a>
  <a href="https://github.com/RecursiveDev/Pasahe/actions/workflows/ci.yml"><img src="https://github.com/RecursiveDev/Pasahe/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="https://github.com/RecursiveDev/Pasahe/releases"><img src="https://img.shields.io/github/v/release/RecursiveDev/Pasahe" alt="Latest release" /></a>
</p>

Pasahe helps tourists, expats, and local commuters estimate fares for road, rail, and ferry transport. It focuses on answering a simple question quickly: how much will this trip cost?

> [!NOTE]
> This app provides fare estimates, not official government fare quotations.

## Features

- Estimate fares for multiple Philippine transport modes, including jeepney, bus, taxi, UV Express, tricycle, pedicab, train, ferry, van, motorcycle, and EDSA Carousel
- Use road-distance calculations for supported road transport and fixed fare matrices for rail and ferry routes
- Download offline map regions and continue using core fare features with limited connectivity
- Cache searched locations locally for faster repeat lookups
- Use map-based origin and destination selection with location suggestions
- Apply passenger discounts for students, senior citizens, and persons with disabilities
- Switch between Material 3 light and dark themes
- Use localized content with English and Tagalog support

## How It Works

The app uses a hybrid fare engine:

- **Road transport** uses distance-aware formulas based on OSRM routing, with offline-friendly fallbacks when network access is unavailable.
- **Rail and ferry transport** use bundled fare matrices for fixed route pricing.
- **Offline support** combines cached map data, cached geocoding results, and fallback routing strategies.

## Tech Stack

- Flutter and Dart
- `flutter_map` and `flutter_map_tile_caching`
- Hive and `shared_preferences`
- `get_it` and `injectable`
- OpenStreetMap Nominatim
- OSRM

## Project Structure

```text
lib/
├── main.dart
└── src/
    ├── core/
    ├── l10n/
    ├── models/
    ├── presentation/
    │   ├── controllers/
    │   ├── screens/
    │   └── widgets/
    ├── repositories/
    └── services/
        ├── connectivity/
        ├── geocoding/
        ├── offline/
        └── routing/
```

## Getting Started

### Prerequisites

- Flutter stable
- Dart SDK 3.9.2 or newer
- Android SDK and a connected device or emulator

### Local setup

```bash
git clone https://github.com/RecursiveDev/Pasahe.git
cd Pasahe
flutter pub get
touch .env
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Development

Useful commands:

```bash
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Release builds are published on the [GitHub Releases](https://github.com/RecursiveDev/Pasahe/releases) page.

## Disclaimer

Fare values are estimates only. Official fares are regulated by the relevant Philippine transport authorities and may change without notice. The project is not affiliated with any government agency.
