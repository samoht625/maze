SCHEME := MazeScreensaver
CONFIG := Release
DERIVED := build/DerivedData
PRODUCT := $(DERIVED)/Build/Products/$(CONFIG)/MazeScreensaver.saver
LOCAL_PRODUCT := build/Local/MazeScreensaver.saver
SOURCES := MazeScreensaver/MazeScreensaverView.swift \
	MazeScreensaver/MazeModel.swift \
	MazeScreensaver/MazePlayback.swift \
	MazeScreensaver/MazeSettings.swift \
	MazeScreensaver/MazeRenderer.swift
# Use an unescaped space here and quote on usage to avoid creating a literal
# "Screen\ Savers" directory.
DEST := $(HOME)/Library/Screen Savers

.PHONY: build build-local clean install install-local uninstall open-settings sign test verify verify-bundle verify-local preview

build:
	xcodebuild -project MazeScreensaver.xcodeproj -scheme "$(SCHEME)" -configuration "$(CONFIG)" \
	  -derivedDataPath "$(DERIVED)" -sdk macosx build

sign: build
	codesign --force --sign - "$(PRODUCT)"
	codesign --verify --deep --strict --verbose=2 "$(PRODUCT)"

install: sign
	./install.sh --install-bundle "$(PRODUCT)" "$(DEST)"

build-local:
	bash Tools/build-local.sh

verify-local: build-local
	xcrun swiftc -parse-as-library -O Tools/VerifyBundle.swift -o build/VerifyBundle
	./build/VerifyBundle "$(LOCAL_PRODUCT)"

install-local: verify-local
	./install.sh --install-bundle "$(LOCAL_PRODUCT)" "$(DEST)"

test:
	swift test

verify:
	mkdir -p build
	swiftc -parse-as-library -D VERIFY -O $(SOURCES) Tools/VerifyScreensaver.swift -o build/VerifyScreensaver
	./build/VerifyScreensaver

verify-bundle: build
	mkdir -p build
	swiftc -parse-as-library -O Tools/VerifyBundle.swift -o build/VerifyBundle
	./build/VerifyBundle "$(PRODUCT)"

preview:
	mkdir -p build
	swiftc -parse-as-library -O $(SOURCES) Tools/PreviewScreensaver.swift -o build/PreviewScreensaver
	./build/PreviewScreensaver

uninstall:
	rm -rf "$(DEST)/MazeScreensaver.saver"

open-settings:
	open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" || true

clean:
	rm -rf "$(DERIVED)" build/Local
	rm -f build/VerifyScreensaver build/VerifyBundle build/PreviewScreensaver

