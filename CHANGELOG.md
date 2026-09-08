# Release notes

## 1.1.0 — 2026-09-08

### Experience
- Coordinated Aurora, Ember, Glacier, and Classic palettes, with a random-palette option.
- Native options for pace, maze density, and exploration progress, saved across displays.
- A distinct start ring, illuminated explorer, subtle dead-end markers, and a finish celebration that respects Reduce Motion.
- Full-maze fitting in compact previews and narrow views.

### Reliability and efficiency
- Isolated, cancelable background generation with stale-result protection during resizing and stop/start.
- Correct forward-path interpolation and frame-independent playback timing.
- Linear-time endpoint searches, cached wall rendering and path geometry, and fewer unnecessary redraws.
- Safer installation with signature checks and rollback on replacement failure.
- Fixed nested installation and Xcode project regeneration.

### Developer tools
- 31 deterministic maze and playback tests.
- Native lifecycle, options, rendering, cross-process preferences, and bundle-loading checks.
- `make preview` to run without installation.
- `make install-local` to build, verify, and install a universal bundle without invoking Xcode plug-ins.

### Local update

Exit the screensaver and quit System Settings, then run:

```bash
cd ~/code/maze
git pull --ff-only origin main
make install-local
make open-settings
```

Select MazeScreensaver and open Options to customize it. The bundle is ad-hoc signed for local use; it is not Developer ID signed or notarized. macOS 13 or later is required. Native harness checks do not replace testing in System Settings and the real screensaver host on every supported macOS release.
