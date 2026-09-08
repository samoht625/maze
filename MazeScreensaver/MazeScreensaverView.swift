import ScreenSaver
import AppKit
import QuartzCore

private final class GenerationRequest {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }
}

@objc(MazeScreensaverView)
final class MazeScreensaverView: ScreenSaverView {
    static let solutionPause: TimeInterval = 3.5
    private static let generationQueue = DispatchQueue(label: "com.tido.MazeScreensaver.generation", qos: .utility)
    private static let preferencesChanged = Notification.Name("com.tido.MazeScreensaver.preferencesChanged")

    private let defaults: UserDefaults
    private var preferences: MazePreferences
    private var theme: MazeTheme
    private var renderer: MazeRenderer?
    private var request: GenerationRequest?
    private var generation = 0
    private var lastBounds = NSRect.zero
    private var lastFrameTime = CACurrentMediaTime()
    private var paused = false
    private var reducedMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    private var optionsController: MazeOptionsController?
    private(set) var playback: MazePlayback?
    private(set) var mazeLayout: MazeLayout?
    private(set) var round = 0

    override var isOpaque: Bool { true }

    override init?(frame: NSRect, isPreview: Bool) {
        defaults = MazePreferences.defaults
        preferences = MazePreferences(defaults: defaults)
        theme = preferences.palette.theme
        super.init(frame: frame, isPreview: isPreview)
        prepare()
    }

    init?(frame: NSRect, isPreview: Bool, defaults: UserDefaults) {
        self.defaults = defaults
        preferences = MazePreferences(defaults: defaults)
        theme = preferences.palette.theme
        super.init(frame: frame, isPreview: isPreview)
        prepare()
    }

    required init?(coder: NSCoder) {
        defaults = MazePreferences.defaults
        preferences = MazePreferences(defaults: defaults)
        theme = preferences.palette.theme
        super.init(coder: coder)
        prepare()
    }

    deinit {
        request?.cancel()
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func prepare() {
        animationTimeInterval = isPreview ? 1.0 / 30.0 : 1.0 / 60.0
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel("Animated maze. A glowing explorer finds the checkered finish.")
        NotificationCenter.default.addObserver(self, selector: #selector(reloadPreferences),
                                               name: Self.preferencesChanged, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(reloadPreferences),
                                                            name: Self.preferencesChanged, object: nil)
        initializeMaze()
    }

    override func startAnimation() {
        super.startAnimation()
        paused = false
        lastFrameTime = CACurrentMediaTime()
        reloadPreferences()
        if renderer == nil && request == nil { initializeMaze() }
        requestDisplay()
    }

    override func stopAnimation() {
        super.stopAnimation()
        paused = true
        cancelGeneration()
    }

    @objc private func reloadPreferences() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.reloadPreferences() }
            return
        }
        let updated = MazePreferences(defaults: defaults)
        guard updated != preferences else { return }
        preferences = updated
        initializeMaze()
    }

    private func cancelGeneration() {
        request?.cancel()
        request = nil
        generation += 1
    }

    private func initializeMaze() {
        cancelGeneration()
        lastBounds = bounds
        playback = nil
        renderer = nil
        mazeLayout = MazeLayout(bounds: bounds, preferences: preferences, isPreview: isPreview)
        theme = preferences.palette.theme
        lastFrameTime = CACurrentMediaTime()
        requestDisplay()
        guard !paused, let layout = mazeLayout else { return }

        let request = GenerationRequest()
        self.request = request
        let generation = self.generation
        Self.generationQueue.async { [weak self] in
            guard !request.isCancelled else { return }
            let grid = MazeGrid(rows: layout.rows, cols: layout.cols)
            let generator = MazeGenerator(grid: grid)
            while !generator.completed {
                guard !request.isCancelled else { return }
                generator.step()
            }
            guard !request.isCancelled else { return }
            var endpoints = MazeSolver.findFarthestEndpoints(grid: grid)
            if Bool.random() { swap(&endpoints.start, &endpoints.end) }
            guard !request.isCancelled else { return }
            let solver = MazeSolver(grid: grid, startIndex: endpoints.start, endIndex: endpoints.end,
                                    strategy: Bool.random() ? .left : .right)
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.paused, !request.isCancelled,
                      self.generation == generation, self.bounds == layout.bounds else { return }
                self.request = nil
                self.playback = MazePlayback(solver: solver)
                self.renderer = MazeRenderer(grid: grid, layout: layout, theme: self.theme)
                self.round += 1
                self.lastFrameTime = CACurrentMediaTime()
                self.requestDisplay()
            }
        }
    }

    override func animateOneFrame() {
        let now = CACurrentMediaTime()
        let delta = max(0, min(0.25, now - lastFrameTime))
        lastFrameTime = now
        updateReducedMotion(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        advance(by: delta)
    }

    private func advance(by delta: TimeInterval) {
        guard !paused else { return }
        if bounds != lastBounds {
            initializeMaze()
            return
        }
        guard let playback else { return }
        let previousPhase = playback.phase
        let previousElapsed = playback.solvedElapsed
        playback.advance(by: delta, stepDuration: preferences.pace.stepDuration)
        if playback.phase == .failed || playback.solvedElapsed >= Self.solutionPause {
            initializeMaze()
            return
        }
        let celebrating = !reducedMotion && (previousElapsed < 1 || playback.solvedElapsed >= Self.solutionPause - 0.5)
        if playback.phase == .solving || previousPhase != playback.phase || celebrating {
            requestDisplay()
        }
    }

    private func requestDisplay() {
        needsDisplay = true
        #if VERIFY
        verificationDisplayRequests += 1
        #endif
    }

    private func updateReducedMotion(_ value: Bool) {
        guard value != reducedMotion else { return }
        reducedMotion = value
        requestDisplay()
    }

    override func draw(_ rect: NSRect) {
        theme.background.setFill()
        rect.fill()
        if let renderer, let playback, renderer.layout.bounds == bounds {
            renderer.draw(playback: playback, scale: window?.backingScaleFactor ?? 1,
                          reducedMotion: reducedMotion, round: round)
        } else if bounds.width >= 240 && bounds.height >= 140 {
            let caption = "Creating a new maze…"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: theme.text.withAlphaComponent(0.5)
            ]
            let size = caption.size(withAttributes: attributes)
            caption.draw(at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2),
                         withAttributes: attributes)
        }
    }

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        if let window = optionsController?.window, window.isVisible { return window }
        optionsController = MazeOptionsController(preferences: MazePreferences(defaults: defaults)) { [weak self] updated in
            guard let self else { return }
            updated.save(to: self.defaults)
            self.reloadPreferences()
            NotificationCenter.default.post(name: Self.preferencesChanged, object: nil)
            DistributedNotificationCenter.default().postNotificationName(Self.preferencesChanged, object: nil,
                                                                          userInfo: nil, deliverImmediately: true)
        }
        return optionsController?.window
    }

    #if VERIFY
    var verificationDisplayRequests = 0
    func verificationAdvance(by delta: TimeInterval) { advance(by: delta) }
    func verificationSetReducedMotion(_ value: Bool) { updateReducedMotion(value) }
    func verificationDraw(scale: CGFloat) {
        guard let renderer, let playback else { return }
        renderer.draw(playback: playback, scale: scale, reducedMotion: reducedMotion, round: round)
    }
    var verificationWallCacheBuilds: Int { renderer?.verificationWallCacheBuilds ?? 0 }
    var verificationWallCacheSize: NSSize { renderer?.verificationWallCacheSize ?? .zero }
    var verificationGeneration: Int { generation }
    var verificationPreferences: MazePreferences { preferences }
    var verificationIsGenerating: Bool { request != nil }
    #endif
}
