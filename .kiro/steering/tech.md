# EasyView - Tech Stack

## Build System

- **IDE**: Xcode
- **Project**: `easyView.xcodeproj`
- **Minimum Deployment**: macOS 12.0

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **AppKit Integration**: NSWindow, NSOpenPanel, NSImage, NSEvent handling
- **No External Dependencies**: Pure Apple frameworks only

## Key Frameworks Used

- `SwiftUI` - Main UI framework
- `AppKit` - Window management, file panels, image handling
- `UniformTypeIdentifiers` - File type identification
- `Foundation` - File system, UserDefaults, bookmarks

## Build Commands

```bash
# Open in Xcode
open easyView.xcodeproj

# Command-line build
xcodebuild -scheme easyView build

# Build for release
xcodebuild -scheme easyView -configuration Release build
```

## App Signing & Distribution

- Uses `export_options.plist` for archive export
- DMG creation via `build_dmg.sh`
- Entitlements in `easyView/easyView.entitlements`

## Code Patterns

- **Singleton**: `ImageCache.shared`, `BookmarkManager.shared`
- **MVVM-lite**: State management via `@State` in views
- **NSViewRepresentable**: Custom AppKit views for scroll/key handling
- **NotificationCenter**: Inter-component communication (e.g., `ImageChanged`, `OpenFilesFromFinder`)
