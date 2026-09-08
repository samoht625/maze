import AppKit
import ScreenSaver

enum MazePace: Int, CaseIterable {
    case calm, flowing, lively

    var title: String { ["Calm", "Flowing", "Lively"][rawValue] }
    var stepDuration: TimeInterval { [0.09, 0.035, 0.012][rawValue] }
}

enum MazeDensity: Int, CaseIterable {
    case relaxed, balanced, intricate

    var title: String { ["Relaxed", "Balanced", "Intricate"][rawValue] }
    var cellSize: CGFloat { [44, 32, 23][rawValue] }
}

enum MazePalette: Int, CaseIterable {
    case aurora, ember, glacier, classic, surprise

    var title: String { ["Aurora", "Ember", "Glacier", "Classic", "Surprise me"][rawValue] }

    var theme: MazeTheme {
        switch self {
        case .aurora:
            return MazeTheme(background: 0x080F18, wall: 0x34475A, active: 0x64E8C1, solution: 0xF5D578)
        case .ember:
            return MazeTheme(background: 0x160E15, wall: 0x59404D, active: 0xFF9278, solution: 0xFFE1A0)
        case .glacier:
            return MazeTheme(background: 0x0B1020, wall: 0x394869, active: 0x7CCFFF, solution: 0xD3B5FF)
        case .classic:
            return MazeTheme(background: 0x000000, wall: 0xE9EDF1, active: 0x38D9F5, solution: 0xF5D547)
        case .surprise:
            return [MazePalette.aurora, .ember, .glacier].randomElement()!.theme
        }
    }
}

struct MazeTheme {
    let background: NSColor
    let wall: NSColor
    let active: NSColor
    let solution: NSColor
    let text = NSColor(calibratedWhite: 0.9, alpha: 1)

    init(background: UInt32, wall: UInt32, active: UInt32, solution: UInt32) {
        self.background = NSColor(hex: background)
        self.wall = NSColor(hex: wall)
        self.active = NSColor(hex: active)
        self.solution = NSColor(hex: solution)
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(calibratedRed: CGFloat((hex >> 16) & 255) / 255,
                  green: CGFloat((hex >> 8) & 255) / 255,
                  blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

struct MazePreferences: Equatable {
    var pace: MazePace = .flowing
    var density: MazeDensity = .balanced
    var palette: MazePalette = .aurora
    var showProgress = true

    static var defaults: UserDefaults {
        ScreenSaverDefaults(forModuleWithName: "com.tido.MazeScreensaver") ?? .standard
    }

    init() {}

    init(defaults: UserDefaults) {
        if let value = defaults.object(forKey: "pace") as? Int {
            pace = MazePace(rawValue: value) ?? .flowing
        }
        if let value = defaults.object(forKey: "density") as? Int {
            density = MazeDensity(rawValue: value) ?? .balanced
        }
        if let value = defaults.object(forKey: "palette") as? Int {
            palette = MazePalette(rawValue: value) ?? .aurora
        }
        if let value = defaults.object(forKey: "showProgress") as? Bool {
            showProgress = value
        }
    }

    func save(to defaults: UserDefaults) {
        defaults.set(pace.rawValue, forKey: "pace")
        defaults.set(density.rawValue, forKey: "density")
        defaults.set(palette.rawValue, forKey: "palette")
        defaults.set(showProgress, forKey: "showProgress")
        defaults.synchronize()
    }
}

final class MazeOptionsController: NSWindowController {
    private let pace = NSPopUpButton()
    private let density = NSPopUpButton()
    private let palette = NSPopUpButton()
    private let progress = NSButton(checkboxWithTitle: "Show exploration progress", target: nil, action: nil)
    private let onApply: (MazePreferences) -> Void

    init(preferences: MazePreferences, onApply: @escaping (MazePreferences) -> Void) {
        self.onApply = onApply
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "Maze Options"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContent(preferences: preferences)
    }

    required init?(coder: NSCoder) { nil }

    private func buildContent(preferences: MazePreferences) {
        guard let content = window?.contentView else { return }
        let title = NSTextField(labelWithString: "Make it your maze.")
        title.font = .systemFont(ofSize: 24, weight: .semibold)
        let subtitle = NSTextField(wrappingLabelWithString: "A little exploration. A satisfying way home.")
        subtitle.textColor = .secondaryLabelColor

        pace.addItems(withTitles: MazePace.allCases.map(\.title))
        density.addItems(withTitles: MazeDensity.allCases.map(\.title))
        palette.addItems(withTitles: MazePalette.allCases.map(\.title))
        pace.selectItem(at: preferences.pace.rawValue)
        density.selectItem(at: preferences.density.rawValue)
        palette.selectItem(at: preferences.palette.rawValue)
        progress.state = preferences.showProgress ? .on : .off
        for (control, name) in [(pace, "Pace"), (density, "Density"), (palette, "Palette")] {
            control.identifier = NSUserInterfaceItemIdentifier(name.lowercased())
            control.setAccessibilityLabel(name)
            control.widthAnchor.constraint(equalToConstant: 270).isActive = true
        }
        progress.identifier = NSUserInterfaceItemIdentifier("progress")
        pace.toolTip = "How quickly the explorer moves through the maze."
        density.toolTip = "Intricate mazes have smaller cells and longer journeys."
        palette.toolTip = "Surprise me chooses a new color palette for each maze."

        let grid = NSGridView(views: [
            [NSTextField(labelWithString: "Pace"), pace],
            [NSTextField(labelWithString: "Density"), density],
            [NSTextField(labelWithString: "Palette"), palette]
        ])
        grid.rowSpacing = 14
        grid.columnSpacing = 24
        grid.column(at: 0).xPlacement = .trailing
        grid.yPlacement = .center

        let note = NSTextField(wrappingLabelWithString: "Changes start a fresh maze on every display. Progress is hidden in small previews.")
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabelColor
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancel.keyEquivalent = "\u{1b}"
        cancel.identifier = NSUserInterfaceItemIdentifier("cancel")
        let apply = NSButton(title: "Apply", target: self, action: #selector(apply(_:)))
        apply.keyEquivalent = "\r"
        apply.identifier = NSUserInterfaceItemIdentifier("apply")
        let buttons = NSStackView(views: [cancel, apply])
        buttons.spacing = 8

        let stack = NSStackView(views: [title, subtitle, grid, progress, note])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.setCustomSpacing(6, after: title)
        stack.setCustomSpacing(26, after: subtitle)
        content.addSubview(stack)
        content.addSubview(buttons)
        stack.translatesAutoresizingMaskIntoConstraints = false
        buttons.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -28),
            note.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            buttons.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 20)
        ])
    }

    @objc private func apply(_ sender: NSButton) {
        var preferences = MazePreferences()
        preferences.pace = MazePace(rawValue: pace.indexOfSelectedItem) ?? .flowing
        preferences.density = MazeDensity(rawValue: density.indexOfSelectedItem) ?? .balanced
        preferences.palette = MazePalette(rawValue: palette.indexOfSelectedItem) ?? .aurora
        preferences.showProgress = progress.state == .on
        onApply(preferences)
        dismiss()
    }

    @objc private func cancel(_ sender: NSButton) { dismiss() }

    private func dismiss() {
        guard let window else { return }
        window.sheetParent?.endSheet(window)
        window.orderOut(nil)
    }
}
