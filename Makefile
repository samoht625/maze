SCHEME := MazeScreensaver
CONFIG := Release
DERIVED := build/DerivedData
PRODUCT := $(DERIVED)/Build/Products/$(CONFIG)/MazeScreensaver.saver
# Use an unescaped space here and quote on usage to avoid creating a literal
# "Screen\ Savers" directory.
DEST := $(HOME)/Library/Screen Savers

.PHONY: build clean install uninstall open-settings sign

build:
	xcodebuild -scheme "$(SCHEME)" -configuration "$(CONFIG)" \
	  -derivedDataPath "$(DERIVED)" -sdk macosx build

sign: build
	codesign --force --sign - "$(PRODUCT)" || true
	xattr -dr com.apple.quarantine "$(PRODUCT)" || true

install: sign
	mkdir -p "$(DEST)"
	rm -rf "$(DEST)/MazeScreensaver.saver"
	cp -R "$(PRODUCT)" "$(DEST)/"

uninstall:
	rm -rf "$(DEST)/MazeScreensaver.saver"

open-settings:
	open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" || true

clean:
	rm -rf "$(DERIVED)"

