# App Icon Assets

This directory contains the source icon assets used to generate launcher icons for Android and iOS.

## Current Source Files

The project currently uses the following files from `assets/icons/PasaheLogo/`:

- `icon-1024x1024.png` for the primary launcher icon source
- `icon-512x512.png` for the Android adaptive icon foreground

## Configuration

Launcher icon generation is configured in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/PasaheLogo/icon-1024x1024.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#0038A8"
  adaptive_icon_foreground: "assets/icons/PasaheLogo/icon-512x512.png"
  min_sdk_android: 21
```

## Regenerating Icons

Run one of the following commands after updating the source images:

```bash
flutter pub run flutter_launcher_icons
```

or

```bash
dart run flutter_launcher_icons
```

## Expected Output

The generator updates launcher icons in the following locations:

- `android/app/src/main/res/mipmap-*/`
- `android/app/src/main/res/mipmap-anydpi-v26/`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Asset Guidelines

When replacing the source files, keep these requirements in mind:

- Use square PNG assets.
- Keep the main icon source at 1024 × 1024 pixels.
- Keep the adaptive foreground icon centered with enough safe padding.
- Avoid transparency in the primary iOS icon source.

## Related Files

- `pubspec.yaml`
- `lib/src/presentation/widgets/app_logo_widget.dart`
- `android/app/src/main/res/`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
