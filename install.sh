#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" != "--install-bundle" ]]; then
    exec make -C "$SCRIPT_DIR" install "$@"
fi

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 --install-bundle PRODUCT DESTINATION" >&2
    exit 2
fi

PRODUCT="$2"
DEST="$3"
if [[ ! -d "$PRODUCT/Contents" ]]; then
    echo "Screensaver bundle not found: $PRODUCT" >&2
    exit 1
fi

mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"
TARGET="$DEST/MazeScreensaver.saver"
# Stage on the destination filesystem so replacement uses renames.
STAGING_DIR="$(mktemp -d "$DEST/.MazeScreensaver.install.XXXXXX")"
STAGED="$STAGING_DIR/MazeScreensaver.saver"
BACKUP="$STAGING_DIR/previous.saver"
REPLACING=false
COMMITTED=false

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ "$COMMITTED" != true ]]; then
        if [[ -e "$BACKUP" || -L "$BACKUP" ]]; then
            if ! rm -rf "$TARGET" || ! mv "$BACKUP" "$TARGET"; then
                echo "Rollback failed. Previous screensaver preserved at: $BACKUP" >&2
                exit 1
            fi
            echo "Restored previous screensaver." >&2
        elif [[ "$REPLACING" == true ]]; then
            if ! rm -rf "$TARGET"; then
                echo "Could not remove failed installation: $TARGET" >&2
                exit 1
            fi
        fi
    fi
    if ! rm -rf "$STAGING_DIR"; then
        echo "Could not remove installation staging directory: $STAGING_DIR" >&2
        exit 1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

ditto "$PRODUCT" "$STAGED"
codesign --verify --deep --strict --verbose=2 "$STAGED"
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    mv "$TARGET" "$BACKUP"
fi
REPLACING=true
mv "$STAGED" "$TARGET"
codesign --verify --deep --strict --verbose=2 "$TARGET"
COMMITTED=true
rm -rf "$STAGING_DIR"
trap - EXIT HUP INT TERM

echo "Installed MazeScreensaver at: $TARGET"
echo "Open Screen Saver settings to select it."

