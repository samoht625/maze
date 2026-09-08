#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/Local
STAGING="$(mktemp -d build/Local/.build.XXXXXX)"
trap 'rm -rf "$STAGING"' EXIT
PRODUCT="$STAGING/MazeScreensaver.saver"
EXECUTABLE="$PRODUCT/Contents/MacOS/MazeScreensaver"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SWIFTC="$(xcrun --find swiftc)"
MINIMUM_OS="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' MazeScreensaver/Info.plist)"
SOURCES=(
    MazeScreensaver/MazeScreensaverView.swift
    MazeScreensaver/MazeModel.swift
    MazeScreensaver/MazePlayback.swift
    MazeScreensaver/MazeSettings.swift
    MazeScreensaver/MazeRenderer.swift
)

mkdir -p "$PRODUCT/Contents/MacOS"
for arch in arm64 x86_64; do
    "$SWIFTC" -parse-as-library -O -warnings-as-errors -sdk "$SDK" \
        -target "$arch-apple-macosx$MINIMUM_OS" -module-name MazeScreensaver \
        -emit-library -Xlinker -bundle "${SOURCES[@]}" -o "$STAGING/$arch"
done
xcrun lipo -create "$STAGING/arm64" "$STAGING/x86_64" -output "$EXECUTABLE"
plutil -convert xml1 -o "$PRODUCT/Contents/Info.plist" MazeScreensaver/Info.plist
plutil -replace CFBundleExecutable -string MazeScreensaver "$PRODUCT/Contents/Info.plist"
codesign --force --sign - "$PRODUCT"
codesign --verify --deep --strict --verbose=2 "$PRODUCT"
xcrun lipo "$EXECUTABLE" -verify_arch arm64 x86_64

rm -rf build/Local/MazeScreensaver.saver
mv "$PRODUCT" build/Local/MazeScreensaver.saver
printf 'Built universal screensaver: build/Local/MazeScreensaver.saver\n'
