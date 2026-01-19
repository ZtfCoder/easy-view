# EasyView - Project Structure

```
easyView/
├── easyView/                    # Main source directory
│   ├── easyViewApp.swift        # App entry point, AppDelegate, window management
│   ├── ContentView.swift        # Main image viewer UI, gestures, navigation
│   ├── ImageCache.swift         # NSCache wrapper for image caching
│   ├── BookmarkManager.swift    # Security-scoped bookmark persistence
│   ├── SettingsView.swift       # Settings UI for managing authorized folders
│   ├── Info.plist               # App configuration, permissions, document types
│   ├── easyView.entitlements    # Sandbox entitlements
│   └── Assets.xcassets/         # App icons and color assets
│
├── easyView.xcodeproj/          # Xcode project configuration
│
├── icon/                        # Source icon files (various sizes)
│
├── build/                       # Build output directory
│
└── Documentation
    ├── README.md                # Main documentation (Chinese)
    ├── BUILD_DMG_GUIDE.md       # DMG creation guide
    ├── HOW_TO_SET_DEFAULT_VIEWER.md  # User guide for default app
    └── XCODE_SETUP.md           # Xcode configuration guide
```

## File Responsibilities

| File | Purpose |
|------|---------|
| `easyViewApp.swift` | App lifecycle, window creation/sizing, file opening from Finder |
| `ContentView.swift` | Image display, zoom/pan gestures, keyboard handling, UI controls |
| `ImageCache.swift` | Memory-efficient image caching (10 images, 50MB limit) |
| `BookmarkManager.swift` | Persist folder access permissions across app launches |
| `SettingsView.swift` | Manage authorized folders list |

## Architecture Notes

- Single-window app with transparent titlebar
- Window size adapts to image dimensions (max 85% of screen)
- Security-scoped bookmarks enable folder access without repeated permission prompts
- Image preloading for smooth navigation (current ± 1)
