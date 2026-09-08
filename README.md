# MazeScreensaver

Current release: **1.1.0** ([release notes](CHANGELOG.md)).

A native macOS screensaver that explores a new maze, finds its way home, and starts again. Watch a glowing path grow through the corridors, leave small markers at dead ends, and turn gold when it reaches the checkered finish.

## Features

- **A different journey each time.** Seeded recursive-backtracking generation creates perfect mazes with one route between any two cells. Two breadth-first searches select the most distant endpoints; a depth-first solver explores with a left- or right-turn preference.
- **Readable animation.** A start ring, bright moving head, checkered finish, and subtle dead-end markers make the exploration easy to follow. A short finish animation leads into the next maze.
- **Native options.** Choose Calm, Flowing, or Lively pace; Relaxed, Balanced, or Intricate density; and Aurora, Ember, Glacier, Classic, or a random palette per maze. Progress feedback is optional.
- **Properly fitted previews.** The whole maze stays inside the view, including compact System Settings previews and narrow displays.
- **Lower rendering overhead.** Static walls are raster-cached, path geometry updates on solver steps, and unchanged solved frames are not redrawn. Animation requests run at 60 Hz on full-size views and 30 Hz in previews. Optional celebration effects respect macOS Reduce Motion.

## Requirements

- macOS 13 Ventura or later.
- Xcode with the macOS SDK for building the `.saver` bundle.
- Swift 5.9 or later for the tests and native preview tools.

The project targets Apple Silicon and Intel Macs. A local build or harness run does not establish compatibility with every macOS release or screensaver host.

## Build and install

```bash
make build
```

The bundle is created at `build/DerivedData/Build/Products/Release/MazeScreensaver.saver`.

To install it for the current user:

```bash
./install.sh
# Or: make install
```

Installation builds and ad-hoc signs the bundle, verifies its signature, and stages the replacement before moving it into `~/Library/Screen Savers/`. The previous installation is restored if replacement fails.

Open Screen Saver settings and select **MazeScreensaver**:

```bash
make open-settings
```

Use the screensaver's **Options** button to change its appearance and pace. **Apply** saves preferences and starts a fresh maze on active displays. **Cancel** leaves the previous settings intact. Progress feedback is automatically hidden in compact previews.

You can also open `MazeScreensaver.xcodeproj` in Xcode and build the MazeScreensaver scheme. For manual installation, double-click the built `.saver` bundle.

## Update an existing local installation

1. Exit any running screensaver or preview, and quit System Settings.
2. From your checkout, pull and install the update:

   ```bash
   cd ~/code/maze
   git pull --ff-only origin main
   make install-local
   ```

   `install-local` builds a universal Apple Silicon/Intel bundle with the Swift compiler, signs it locally, verifies bundle loading, and safely replaces `~/Library/Screen Savers/MazeScreensaver.saver`. It bypasses `xcodebuild` and its plug-ins; the selected developer tools must still provide Swift and a macOS SDK. Your saved Maze preferences are preserved.

3. Reopen settings and preview **MazeScreensaver**:

   ```bash
   make open-settings
   ```

   Open **Options** for pace, density, and palette choices. If macOS continues showing the old version, quit System Settings and, while no screensaver is active, run `killall legacyScreenSaver` to stop the cached third-party screensaver host. This also stops any other third-party screensavers in that host. Reopen settings; if it remains stale, log out and back in.

Check the installed version:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$HOME/Library/Screen Savers/MazeScreensaver.saver/Contents/Info.plist"
```

It should print `1.1.0`. To build without installing, use `make build-local`; the bundle is written to `build/Local/MazeScreensaver.saver`. Use `make verify-local` to build and check bundle loading.

## Preview without installing

```bash
make preview
```

This opens the actual AppKit screensaver in a resizable native window. Use **Maze Preview → Maze Options…** or **⌘,** for options and **⌘Q** to quit. The preview shares saved preferences with the installed screensaver.

## Tests and native verification

```bash
make test           # Deterministic maze and playback tests
make verify         # Actual AppKit view, lifecycle, options, and PNG captures
make verify-bundle  # Build and load the .saver through its principal class
```

The native verification command requires a macOS graphical login session. It checks generation through solution and restart, compact previews, rapid resizing, zero bounds, stop/start, redraw suppression, 1×/2× wall caching, all palettes, and options persistence across multiple views and a separate host process. It uses an isolated preferences domain and writes maze captures plus a native-cell options layout to `build/verification/`; the latter is not a composited window screenshot. It does not install the screensaver or change your active screensaver.

The harness is a repeatable development check, not a replacement for testing in System Settings and the macOS screensaver host on supported OS versions.

## Project structure

```text
MazeScreensaver/
  MazeModel.swift            Grid, generator, and solver
  MazePlayback.swift         Frame-independent exploration state
  MazeRenderer.swift         Adaptive layout and cached native drawing
  MazeSettings.swift         Preferences, palettes, and options sheet
  MazeScreensaverView.swift  ScreenSaver lifecycle and generation scheduling
  Info.plist                 Bundle metadata
Tests/MazeCoreTests/         Deterministic core regression tests
Tools/                      Native preview and verification hosts
MazeScreensaver.xcodeproj/   Screensaver bundle target
Package.swift               Testable core package
Makefile                    Build, install, preview, and test commands
```

`create_xcode_project.sh` regenerates the Xcode project if needed. Normal builds do not require regeneration.

## Troubleshooting

**The screensaver does not appear:** Check that `~/Library/Screen Savers/MazeScreensaver.saver` exists, then reopen System Settings. Run `make verify-bundle` to test whether the local bundle loads.

**Xcode reports a required plug-in failed to load:** A mismatch between Xcode and installed developer frameworks can stop `xcodebuild` before compilation. Complete Xcode's first-launch setup or repair/update the Xcode installation; `make test` and `make verify` may still work through the Swift compiler.

**Signing or permission errors:** Installation stops if signing or signature verification fails. Confirm Xcode is selected with `xcode-select -p` and that you can write to `~/Library/Screen Savers/`. Local ad-hoc signing is not Developer ID signing or notarization for distribution.

**Manually copied bundle is quarantined:** For a bundle you built and trust, remove quarantine with:

```bash
xattr -dr com.apple.quarantine ~/Library/Screen\ Savers/MazeScreensaver.saver
```

To uninstall:

```bash
make uninstall
```

## License

Copyright Anysphere Inc.
