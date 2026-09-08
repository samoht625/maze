import AppKit
import ScreenSaver

@main
final class PreviewScreensaver: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var saver: MazeScreensaverView!
    private var timer: Timer?

    static func main() {
        let app = NSApplication.shared
        let delegate = PreviewScreensaver()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
        withExtendedLifetime(delegate) {}
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 740),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Maze Preview"
        window.minSize = NSSize(width: 260, height: 200)
        window.center()
        saver = MazeScreensaverView(frame: window.contentView!.bounds, isPreview: false)
        saver.autoresizingMask = [.width, .height]
        window.contentView = saver
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        let options = NSMenuItem(title: "Maze Options…", action: #selector(showOptions), keyEquivalent: ",")
        options.target = self
        appMenu.addItem(options)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Maze Preview", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApplication.shared.mainMenu = menu
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        saver.startAnimation()
        timer = Timer.scheduledTimer(withTimeInterval: saver.animationTimeInterval, repeats: true) { [weak self] _ in
            self?.saver.animateOneFrame()
        }
    }

    @objc private func showOptions() {
        guard window.attachedSheet == nil, let sheet = saver.configureSheet else { return }
        window.beginSheet(sheet)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        saver.stopAnimation()
    }
}
