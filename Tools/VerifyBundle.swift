import AppKit
import ScreenSaver

@main
struct VerifyBundle {
    static func main() throws {
        _ = NSApplication.shared
        guard CommandLine.arguments.count == 2 else { fatalError("Pass the path to a .saver bundle") }
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        guard let bundle = Bundle(url: url) else { fatalError("Bundle could not be opened") }
        try bundle.loadAndReturnError()
        guard let type = bundle.principalClass as? ScreenSaverView.Type,
              let view = type.init(frame: NSRect(x: 0, y: 0, width: 320, height: 220), isPreview: true) else {
            fatalError("The built bundle must expose an instantiable ScreenSaverView principal class")
        }
        view.startAnimation()
        for _ in 0..<30 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
            view.animateOneFrame()
        }
        guard view.hasConfigureSheet, view.configureSheet != nil else { fatalError("Options sheet is unavailable") }
        view.stopAnimation()
        print("PASS: built bundle loads, principal class instantiates, animates, and exposes options")
    }
}
