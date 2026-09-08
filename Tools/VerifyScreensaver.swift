import AppKit
import ScreenSaver

private enum VerificationError: Error {
    case failed(String)
}

@main
struct VerifyScreensaver {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw VerificationError.failed(message) }
    }

    static func pumpEvents(for duration: TimeInterval) {
        let deadline = Date(timeIntervalSinceNow: duration)
        repeat {
            while let event = NSApp.nextEvent(matching: .any, until: .distantPast, inMode: .default, dequeue: true) {
                NSApp.sendEvent(event)
            }
            NSApp.updateWindows()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.005))
        } while Date() < deadline
    }

    static func waitUntil(_ message: String, _ condition: () -> Bool) throws {
        let deadline = Date(timeIntervalSinceNow: 10)
        while !condition() && Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.005))
        }
        try require(condition(), message)
    }

    static func capture(_ view: NSView, name: String, scale: CGFloat = 1) throws {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                      pixelsWide: Int(view.bounds.width * scale),
                                      pixelsHigh: Int(view.bounds.height * scale),
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = view.bounds.size
        if let saver = view as? MazeScreensaverView {
            let context = NSGraphicsContext(bitmapImageRep: bitmap)!
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            saver.verificationDraw(scale: scale)
            NSGraphicsContext.restoreGraphicsState()
        } else {
            // Hosted AppKit controls can return empty offscreen snapshots.
            view.layoutSubtreeIfNeeded()
            let context = NSGraphicsContext(bitmapImageRep: bitmap)!
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            NSColor.windowBackgroundColor.setFill()
            view.bounds.fill()
            for child in descendants(of: view) {
                guard !child.isHidden else { continue }
                let frame = child.convert(child.bounds, to: view)
                if let text = child as? NSTextField {
                    text.attributedStringValue.draw(in: frame)
                } else if let control = child as? NSControl {
                    (control.cell?.copy() as? NSCell)?.draw(withFrame: frame, in: view)
                }
            }
            NSGraphicsContext.restoreGraphicsState()
        }
        let data = bitmap.representation(using: .png, properties: [:])!
        try data.write(to: URL(fileURLWithPath: "build/verification/\(name).png"))
    }

    static func descendants(of view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap { descendants(of: $0) }
    }

    static func control<T: NSView>(_ id: String, in window: NSWindow, as type: T.Type) throws -> T {
        guard let view = window.contentView,
              let result = descendants(of: view).first(where: { $0.identifier?.rawValue == id }) as? T else {
            throw VerificationError.failed("Missing \(id) control")
        }
        return result
    }

    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        if CommandLine.arguments.count == 5 && CommandLine.arguments[1] == "--watch-preferences" {
            let defaults = UserDefaults(suiteName: CommandLine.arguments[2])!
            let view = MazeScreensaverView(frame: NSRect(x: 0, y: 0, width: 200, height: 140), isPreview: true, defaults: defaults)!
            view.startAnimation()
            defer { view.stopAnimation() }
            try Data().write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
            try waitUntil("Preferences reach a separate host process") {
                view.verificationPreferences.palette.rawValue == Int(CommandLine.arguments[4])
            }
            print("PASS: distributed preferences update a separate host process")
            return
        }
        try FileManager.default.createDirectory(atPath: "build/verification", withIntermediateDirectories: true)
        let suite = "com.tido.MazeScreensaver.verification.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var preferences = MazePreferences()
        preferences.pace = .lively
        preferences.save(to: defaults)
        try require(MazePreferences(defaults: defaults) == preferences, "Preferences round-trip")
        defaults.set(900, forKey: "pace")
        defaults.set(-3, forKey: "density")
        defaults.set(99, forKey: "palette")
        let repaired = MazePreferences(defaults: defaults)
        try require(repaired.pace == .flowing && repaired.density == .balanced && repaired.palette == .aurora,
                    "Invalid preference values fall back safely")
        preferences.save(to: defaults)

        for size in [NSSize(width: 320, height: 220), NSSize(width: 180, height: 120),
                     NSSize(width: 80, height: 600), NSSize(width: 1200, height: 100),
                     NSSize(width: 1920, height: 1080), NSSize(width: 7680, height: 4320), NSSize(width: 2, height: 2)] {
            for density in MazeDensity.allCases {
                preferences.density = density
                for preview in [true, false] {
                    let bounds = NSRect(origin: NSPoint(x: 12, y: 7), size: size)
                    let layout = MazeLayout(bounds: bounds, preferences: preferences, isPreview: preview)!
                    try require(bounds.insetBy(dx: -0.01, dy: -0.01).contains(layout.mazeRect), "Maze must fit \(size)")
                    try require(layout.rows * layout.cols <= 14_000, "Grid cell budget")
                    try require(layout.cellSize > 0 && layout.rows > 0 && layout.cols > 0, "Positive grid geometry")
                }
            }
        }
        try require(MazeLayout(bounds: .zero, preferences: preferences, isPreview: true) == nil, "Empty bounds defer generation")
        preferences.density = .balanced
        preferences.save(to: defaults)
        let previewCounts = MazeDensity.allCases.map { density -> Int in
            var options = MazePreferences()
            options.density = density
            let layout = MazeLayout(bounds: NSRect(x: 0, y: 0, width: 320, height: 220), preferences: options, isPreview: true)!
            return layout.rows * layout.cols
        }
        try require(previewCounts[0] < previewCounts[1] && previewCounts[1] < previewCounts[2], "Preview shows distinct density settings")
        print("PASS: layout matrix, preview densities, and preference validation")

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 740),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        let saver = MazeScreensaverView(frame: window.contentView!.bounds, isPreview: false, defaults: defaults)!
        saver.autoresizingMask = [.width, .height]
        window.contentView = saver
        window.orderFront(nil)
        saver.startAnimation()
        defer { saver.stopAnimation(); window.orderOut(nil) }
        try waitUntil("Desktop generation completes") { saver.playback != nil }
        try require(saver.animationTimeInterval == 1.0 / 60.0, "Desktop frame budget")
        try capture(saver, name: "desktop-start")
        let cacheBuilds = saver.verificationWallCacheBuilds
        try capture(saver, name: "desktop-start")
        try require(saver.verificationWallCacheBuilds == cacheBuilds, "Static wall cache is reused")
        try capture(saver, name: "desktop-retina", scale: 2)
        try require(saver.verificationWallCacheBuilds == cacheBuilds + 1 && saver.verificationWallCacheSize == NSSize(width: 2200, height: 1480), "Wall cache rebuilds at 2x")
        try capture(saver, name: "desktop-retina", scale: 2)
        try require(saver.verificationWallCacheBuilds == cacheBuilds + 1, "Retina cache is reused")
        saver.verificationSetReducedMotion(false)
        saver.verificationDisplayRequests = 0
        saver.verificationAdvance(by: 0.01)
        try require(saver.verificationDisplayRequests > 0, "Exploration requests a display update")
        var sawBacktrack = false
        for frame in 0..<6000 {
            saver.verificationAdvance(by: 1.0 / 30.0)
            if saver.playback?.isBacktracking == true { sawBacktrack = true }
            if frame == 100 { try capture(saver, name: "desktop-exploring", scale: 2) }
            if saver.playback?.phase == .solved { break }
        }
        try require(saver.playback?.phase == .solved, "Desktop solver reaches finish")
        try capture(saver, name: "desktop-solved")
        saver.verificationDisplayRequests = 0
        saver.verificationAdvance(by: 0.1)
        try require(saver.verificationDisplayRequests > 0, "Celebration requests redraws")
        saver.verificationDisplayRequests = 0
        saver.verificationSetReducedMotion(true)
        try require(saver.verificationDisplayRequests > 0, "Enabling Reduce Motion erases the celebration")
        saver.verificationDisplayRequests = 0
        saver.verificationAdvance(by: 0.1)
        try require(saver.verificationDisplayRequests == 0, "Reduced Motion leaves solved frames static")
        saver.verificationSetReducedMotion(false)
        while saver.playback!.solvedElapsed < 1 { saver.verificationAdvance(by: 0.1) }
        saver.verificationDisplayRequests = 0
        saver.verificationAdvance(by: 0.1)
        try require(saver.verificationDisplayRequests == 0, "Stable solved pause skips redraws")
        while saver.playback!.solvedElapsed < MazeScreensaverView.solutionPause - 0.55 { saver.verificationAdvance(by: 0.1) }
        saver.verificationDisplayRequests = 0
        saver.verificationAdvance(by: 0.1)
        try require(saver.verificationDisplayRequests > 0, "Fade requests redraws")
        let oldRound = saver.round
        for _ in 0..<4 { saver.verificationAdvance(by: 0.25) }
        try waitUntil("Next maze appears after celebration") { saver.round > oldRound }
        print("PASS: generation, exploration, finish, and automatic next maze; backtracking observed: \(sawBacktrack)")

        saver.setFrameSize(NSSize(width: 8000, height: 4500))
        saver.verificationAdvance(by: 0.01)
        saver.setFrameSize(NSSize(width: 220, height: 160))
        saver.verificationAdvance(by: 0.01)
        saver.stopAnimation()
        let cancelledGeneration = saver.verificationGeneration
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        try require(saver.playback == nil && !saver.verificationIsGenerating, "Stopped generation must not publish")
        saver.startAnimation()
        try waitUntil("Restart generation completes") { saver.playback != nil }
        try require(saver.verificationGeneration > cancelledGeneration, "Restart invalidates old generation")
        try require(saver.mazeLayout?.bounds.size == NSSize(width: 220, height: 160), "Newest resize owns the published maze")
        let frozenProgress = saver.playback!.progress
        let frozenSteps = saver.playback!.stepsTaken
        saver.stopAnimation()
        saver.verificationDisplayRequests = 0
        saver.verificationAdvance(by: 0.25)
        try require(saver.verificationDisplayRequests == 0, "Stopped playback requests no redraws")
        try require(saver.playback?.progress == frozenProgress && saver.playback?.stepsTaken == frozenSteps, "Stopped playback is frozen")
        saver.startAnimation()
        saver.setFrameSize(.zero)
        saver.verificationAdvance(by: 0.01)
        try require(saver.playback == nil && !saver.verificationIsGenerating, "Zero bounds schedule no generation")
        saver.setFrameSize(NSSize(width: 1100, height: 740))
        saver.verificationAdvance(by: 0.01)
        try waitUntil("Restore nonzero bounds") { saver.playback != nil }
        print("PASS: rapid resizing, cancellation, stop/start, and zero bounds")

        let preview = MazeScreensaverView(frame: NSRect(x: 0, y: 0, width: 320, height: 220), isPreview: true, defaults: defaults)!
        preview.startAnimation()
        defer { preview.stopAnimation() }
        try waitUntil("Concurrent preview generation") { preview.playback != nil }
        try require(preview.animationTimeInterval == 1.0 / 30.0 && preview.mazeLayout?.footer == nil, "Compact preview budget and layout")
        for _ in 0..<40 { preview.verificationAdvance(by: 0.05) }
        try capture(preview, name: "compact-preview", scale: 2)

        let original = MazePreferences(defaults: defaults)
        let cancelSheet = saver.configureSheet!
        window.beginSheet(cancelSheet)
        let cancelledPace = try control("pace", in: cancelSheet, as: NSPopUpButton.self)
        cancelledPace.selectItem(at: MazePace.calm.rawValue)
        try control("cancel", in: cancelSheet, as: NSButton.self).performClick(nil)
        try require(MazePreferences(defaults: defaults) == original, "Cancel preserves settings")
        pumpEvents(for: 0.3)
        let readyFile = "build/verification/preferences-\(UUID().uuidString).ready"
        let separateHost = Process()
        separateHost.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        separateHost.arguments = ["--watch-preferences", suite, readyFile, String(MazePalette.ember.rawValue)]
        try separateHost.run()
        defer {
            if separateHost.isRunning { separateHost.terminate(); separateHost.waitUntilExit() }
            try? FileManager.default.removeItem(atPath: readyFile)
        }
        try waitUntil("Separate preferences host starts") { FileManager.default.fileExists(atPath: readyFile) }
        let options = saver.configureSheet!
        window.beginSheet(options)
        pumpEvents(for: 0.4)
        options.displayIfNeeded()
        try control("pace", in: options, as: NSPopUpButton.self).selectItem(at: MazePace.calm.rawValue)
        try control("density", in: options, as: NSPopUpButton.self).selectItem(at: MazeDensity.relaxed.rawValue)
        try control("palette", in: options, as: NSPopUpButton.self).selectItem(at: MazePalette.ember.rawValue)
        try control("progress", in: options, as: NSButton.self).performClick(nil)
        options.contentView!.layoutSubtreeIfNeeded()
        let content = options.contentView!
        for id in ["pace", "density", "palette", "progress", "cancel", "apply"] {
            let control = try control(id, in: options, as: NSControl.self)
            try require(content.bounds.contains(control.convert(control.bounds, to: content)), "Options control \(id) fits inside sheet")
        }
        try capture(content, name: "options-layout")
        try control("apply", in: options, as: NSButton.self).performClick(nil)
        try waitUntil("Separate host consumes the saved preferences") { !separateHost.isRunning }
        try require(separateHost.terminationStatus == 0, "Distributed preferences propagation succeeds")
        let applied = MazePreferences(defaults: defaults)
        try require(applied.pace == .calm && applied.density == .relaxed && applied.palette == .ember && !applied.showProgress,
                    "Apply writes all chosen settings")
        try require(saver.verificationPreferences == applied && preview.verificationPreferences == applied,
                    "Settings propagate across active views")
        try waitUntil("Applied settings regenerate both views") { saver.playback != nil && preview.playback != nil }
        try require(saver.mazeLayout?.footer == nil, "Progress option updates layout")
        pumpEvents(for: 0.3)
        let reopened = saver.configureSheet!
        let reopenedPace = try control("pace", in: reopened, as: NSPopUpButton.self)
        try require(reopenedPace.indexOfSelectedItem == MazePace.calm.rawValue,
                    "Reopened sheet reflects persisted settings")
        let renewed = MazeScreensaverView(frame: NSRect(x: 0, y: 0, width: 200, height: 140), isPreview: true, defaults: defaults)!
        try require(renewed.verificationPreferences == applied, "New views load saved settings")
        renewed.stopAnimation()
        print("PASS: native options Cancel, Apply, reopen, persistence, and cross-view consistency")

        for palette in MazePalette.allCases {
            preferences.palette = palette
            preferences.save(to: defaults)
            saver.stopAnimation()
            saver.startAnimation()
            try waitUntil("Palette generation") { saver.playback != nil }
            for _ in 0..<100 { saver.verificationAdvance(by: 0.05) }
            try capture(saver, name: "palette-\(palette.title.replacingOccurrences(of: " ", with: "-"))")
        }
        print("PASS: all palettes render; maze captures and a native-cell options layout saved to build/verification")
    }
}
