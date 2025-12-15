# App Launcher Icon Setup

This directory contains the source icons for generating the app launcher icons across Android and iOS platforms.

## Required Files

You need to provide the following icon files:

### 1. `app_icon.png` (Required)
- **Dimensions**: 1024x1024 pixels
- **Format**: PNG
- **Purpose**: Main app icon for iOS and fallback for Android
- **Design Requirements**:
  - Use a **bus icon** (Material Icons `directions_bus`) as the central element
  - **Background color**: Philippine flag blue (#0038A8)
  - **Icon color**: White
  - **No transparency** (alpha channel will be removed for iOS)
  - The icon should match the `AppLogoWidget` design in the app

### 2. `app_icon_foreground.png` (Required for Android Adaptive Icons)
- **Dimensions**: 1024x1024 pixels (with safe zone)
- **Format**: PNG with transparency
- **Purpose**: Foreground layer for Android adaptive icons
- **Design Requirements**:
  - **White bus icon** centered on a **transparent background**
  - Keep the icon within the safe zone (centered 66% of the image)
  - This allows Android to apply various shapes (circle, squircle, etc.)

## Color Scheme

| Element | Color | Hex Code |
|---------|-------|----------|
| Background | Philippine Flag Blue | #0038A8 |
| Icon (Bus) | White | #FFFFFF |

## Generating Icons

Once you have placed both PNG files in this directory, run:

```bash
flutter pub run flutter_launcher_icons
```

Or on newer Flutter versions:

```bash
dart run flutter_launcher_icons
```

## What Gets Generated

The command will generate:

### Android
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)
- Adaptive icon resources in `mipmap-anydpi-v26/`

### iOS
- All required sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Sizes: 20, 29, 40, 60, 76, 83.5, 1024 (with @1x, @2x, @3x variants)

## Creating the Icon Images

Since Flutter cannot render widgets to PNG files programmatically at build time, you need to create the icon images manually using one of these methods:

### Option 1: Design Software
Use Figma, Sketch, Adobe XD, or similar to create the icons:
1. Create a 1024x1024 canvas
2. Fill background with #0038A8
3. Add a white bus icon (centered, about 60% of canvas size)
4. Export as PNG

### Option 2: Online Tools
Use icon generators like:
- [App Icon Generator](https://appicon.co/)
- [MakeAppIcon](https://makeappicon.com/)

### Option 3: Screenshot from App
1. Run the app and navigate to a screen showing the `AppLogoWidget`
2. Take a screenshot of the logo
3. Edit to 1024x1024 with square aspect ratio

## Configuration Reference

The `pubspec.yaml` contains the following configuration:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#0038A8"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  min_sdk_android: 21
```

## Troubleshooting

### "Image not found" error
Ensure both `app_icon.png` and `app_icon_foreground.png` exist in this directory.

### iOS icon has white corners
This is expected. iOS automatically applies rounded corners to app icons.

### Android icon looks different on different devices
Android adaptive icons allow manufacturers to apply different shapes. The `adaptive_icon_foreground.png` with transparent background ensures your icon looks good in all shapes.

## Related Files

- [`lib/src/presentation/widgets/app_logo_widget.dart`](../../lib/src/presentation/widgets/app_logo_widget.dart) - The in-app logo widget that the icon design should match