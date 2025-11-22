# App Icon Setup Instructions

## Overview
The ASCENDR app icon has been configured. You need to add the actual icon image files.

## Icon Design
The icon should feature:
- A stylized mountain graphic (black triangle with white jagged peaks)
- A horizontal dumbbell icon centered in the mountain base
- The text "ASCENDR" in bold uppercase below the graphic
- Black and white color scheme

## Required Files

Place the following image files in: `Ascendr/Ascendr/Assets.xcassets/AppIcon.appiconset/`

1. **AppIcon-1024.png** (1024x1024 pixels)
   - Standard app icon for iOS
   - Should be the ASCENDR logo on white/transparent background

2. **AppIcon-1024-dark.png** (1024x1024 pixels) - Optional
   - Dark mode variant (if different from standard)
   - Can be the same as AppIcon-1024.png if no dark mode variant needed

3. **AppIcon-1024-tinted.png** (1024x1024 pixels) - Optional
   - Tinted variant for iOS
   - Can be the same as AppIcon-1024.png if no tinted variant needed

## Image Requirements

- **Format**: PNG
- **Size**: 1024x1024 pixels (exactly)
- **Color Space**: sRGB
- **Background**: Transparent or white
- **No rounded corners**: iOS will apply the rounded corners automatically

## Steps to Add Icon

1. Create or export your ASCENDR logo as a 1024x1024 PNG image
2. Name it `AppIcon-1024.png`
3. Copy it to: `Ascendr/Ascendr/Assets.xcassets/AppIcon.appiconset/`
4. (Optional) Create dark mode and tinted variants if needed
5. In Xcode, the icon should appear automatically in the asset catalog
6. Clean build folder (Cmd+Shift+K) and rebuild

## Notes

- The icon should be recognizable at small sizes (home screen icons are displayed at various sizes)
- Ensure good contrast between the logo elements and background
- Test the icon on both light and dark backgrounds in iOS Settings

