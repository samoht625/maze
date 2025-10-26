# MazeScreensaver

An animated maze generator and solver screensaver for macOS. Watch as it generates mazes using recursive backtracking, then solves them with wall-following algorithms, displaying the solution with smooth animations.

## What This Screensaver Does

This screensaver creates an engaging visual experience:

1. **Maze Generation**: Generates a perfect maze (one unique path between any two points) using recursive backtracking
2. **Intelligent Solving**: Finds the longest path in the maze between two endpoints
3. **Animated Exploration**: Visualizes the solving process with colorful animated paths
4. **Solution Display**: Shows the final solution as a glowing golden path
5. **Continuous Loop**: Automatically generates a new maze after solving

## Features

- 🎨 **Dynamic Generation**: Creates unique mazes every time
- 🚀 **Smart Solving**: Uses left-hand or right-hand wall-following rules
- ✨ **Smooth Animations**: Fluid path exploration with interpolated movements
- 🎯 **Beautiful Visuals**: Colorful paths, rounded corners, and checkered flags
- ⚡ **High Performance**: Optimized for any screen size

## Compatibility

### macOS Version Support

| macOS Version | Status | Notes |
|--------------|---------|-------|
| macOS 15 Sequoia | ✅ Fully tested | Recommended |
| macOS 14 Sonoma | ✅ Compatible | Should work without issues |
| macOS 13 Ventura | ✅ Compatible | Minimum supported version |
| macOS 12 and earlier | ❌ Not supported | Requires macOS 13.0+ |

### Architecture Support

- ✅ Apple Silicon (M1, M2, M3, M4)
- ✅ Intel-based Macs

### Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15 or later (or Xcode Command Line Tools)
- **Swift**: 5.9 or later
- **Display**: Works on any resolution (automatically scales)

## Building

### Using the Command Line (Recommended)

Build the screensaver:

```bash
make build
```

This will create `MazeScreensaver.saver` in `build/DerivedData/Build/Products/Release/`.

### Using Xcode

1. Open `MazeScreensaver.xcodeproj` in Xcode
2. Select the "MazeScreensaver" scheme
3. Press `Cmd+B` to build (or Product → Build)
4. The `.saver` bundle will be in the build products directory

## Installation

### Quick Install

The easiest way to install:

```bash
./install.sh
```

Or use make directly:

```bash
make install
```

This will:
1. Build the screensaver
2. Code sign it (ad-hoc signing for local use)
3. Remove any quarantine attributes
4. Copy it to `~/Library/Screen Savers/`

### Manual Installation

If you prefer to install manually:

1. Build the screensaver: `make build`
2. Open Finder and navigate to `build/DerivedData/Build/Products/Release/`
3. Double-click `MazeScreensaver.saver`
4. Click "Install" when prompted

### Opening Screen Saver Settings

After installation, you can quickly open the Screen Saver settings:

```bash
make open-settings
```

Or manually: **System Settings** → **Lock Screen** → **Screen Saver**

Select "MazeScreensaver" from the list to preview or set it as your screensaver.

## Uninstallation

To remove the screensaver:

```bash
make uninstall
```

Or manually delete:

```bash
rm -rf ~/Library/Screen\ Savers/MazeScreensaver.saver
```

## Troubleshooting

### The screensaver doesn't appear in System Settings

1. Make sure you've run `make install` or `./install.sh`
2. Try restarting System Settings or your Mac
3. Ensure the `.saver` bundle exists in `~/Library/Screen Savers/`

### Code signing warnings

The Makefile uses ad-hoc signing (`-`) which is fine for local use. If you see signing warnings:
- The `sign` target handles this automatically
- For distribution, you may want to use a Developer ID certificate

### Permission errors

If you get permission errors during installation:
- Make sure you have write access to `~/Library/Screen Savers/`
- You may need to create the directory: `mkdir -p ~/Library/Screen\ Savers/`

### Quarantine issues

The Makefile automatically removes quarantine attributes. If you manually install:
```bash
xattr -dr com.apple.quarantine ~/Library/Screen\ Savers/MazeScreensaver.saver
```

## Customization

To customize the screensaver:

1. Edit `MazeScreensaver/MazeScreensaverView.swift`
2. Add your animation logic in the `animateOneFrame()` and `draw(_:)` methods
3. Rebuild and reinstall: `make install`

## Project Structure

```
MazeScreensaver/
├── MazeScreensaver.xcodeproj/    # Xcode project
├── MazeScreensaver/               # Source files
│   ├── MazeScreensaverView.swift  # Main screensaver view
│   └── Info.plist                 # Bundle configuration
├── Makefile                       # Build automation
├── install.sh                     # Installation script
├── README.md                      # This file
└── .gitignore                     # Git ignore rules
```

## License

Copyright Anysphere Inc.

