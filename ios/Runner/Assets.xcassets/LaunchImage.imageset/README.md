# Launch Image Assets

This directory contains the iOS launch image assets used by the Runner target.

## Files

- `LaunchImage.png`
- `LaunchImage@2x.png`
- `LaunchImage@3x.png`
- `Contents.json`

## Updating the Launch Image

You can update these assets in either of the following ways:

1. Replace the existing image files in this directory while keeping the same filenames.
2. Open `ios/Runner.xcworkspace` in Xcode and update `Runner/Assets.xcassets/LaunchImage.imageset` directly.

## Notes

- Keep the asset names in sync with `Contents.json`.
- Use the correct image scale for each file variant.
- Rebuild the iOS app after changing launch image assets.
