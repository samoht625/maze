import AppKit

struct MazeLayout {
    let bounds: NSRect
    let rows: Int
    let cols: Int
    let cellSize: CGFloat
    let origin: NSPoint
    let footer: NSRect?

    init?(bounds: NSRect, preferences: MazePreferences, isPreview: Bool) {
        guard bounds.width.isFinite, bounds.height.isFinite,
              bounds.width >= 2, bounds.height >= 2 else { return nil }
        self.bounds = bounds
        let margin = min(24, min(bounds.width, bounds.height) * 0.045)
        let footerHeight: CGFloat = preferences.showProgress && !isPreview && bounds.width >= 480 && bounds.height >= 320 ? 44 : 0
        let available = bounds.insetBy(dx: margin, dy: margin)
        let width = available.width
        let height = available.height - footerHeight
        let fitScale = min(1, min(width, height) / ((isPreview ? 12 : 8) * MazeDensity.balanced.cellSize))
        let preferredSize = max(1, preferences.density.cellSize * fitScale)
        let targetSize = max(preferredSize, sqrt(width * height / 14_000))
        cols = max(1, Int(width / targetSize))
        rows = max(1, Int(height / targetSize))
        cellSize = min(width / CGFloat(cols), height / CGFloat(rows))
        origin = NSPoint(x: available.minX + (width - CGFloat(cols) * cellSize) / 2,
                         y: available.minY + footerHeight + (height - CGFloat(rows) * cellSize) / 2)
        footer = footerHeight > 0 ? NSRect(x: origin.x, y: available.minY, width: CGFloat(cols) * cellSize, height: 30) : nil
    }

    var mazeRect: NSRect {
        NSRect(x: origin.x, y: origin.y, width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
    }

    var wallThickness: CGFloat { max(0.5, cellSize * 0.065) }

    func center(of index: Int) -> NSPoint {
        NSPoint(x: origin.x + (CGFloat(index % cols) + 0.5) * cellSize,
                y: origin.y + (CGFloat(rows - 1 - index / cols) + 0.5) * cellSize)
    }
}

final class MazeRenderer {
    let grid: MazeGrid
    let layout: MazeLayout
    let theme: MazeTheme
    private var wallImage: CGImage?
    private var wallScale: CGFloat = 0
    private var revision = -1
    private var settledPath = NSBezierPath()
    private var settledEnd: Int?
    private var solutionPath = NSBezierPath()
    private let pebbles = NSBezierPath()
    private var pebbleCount = 0
    #if VERIFY
    private(set) var verificationWallCacheBuilds = 0
    var verificationWallCacheSize: NSSize {
        NSSize(width: wallImage?.width ?? 0, height: wallImage?.height ?? 0)
    }
    #endif

    init(grid: MazeGrid, layout: MazeLayout, theme: MazeTheme) {
        self.grid = grid
        self.layout = layout
        self.theme = theme
    }

    func draw(playback: MazePlayback, scale: CGFloat, reducedMotion: Bool, round: Int) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        theme.background.setFill()
        layout.bounds.fill()
        NSGraphicsContext.current?.shouldAntialias = true
        updatePaths(playback)

        theme.wall.withAlphaComponent(0.65).setFill()
        pebbles.fill()

        let color = playback.phase == .solved ? theme.solution : theme.active
        let path = playback.phase == .solved ? solutionPath : settledPath
        stroke(path, color: color)
        if playback.phase == .solving, let head = headPosition(playback) {
            if let last = settledEnd {
                let segment = NSBezierPath()
                segment.move(to: layout.center(of: last))
                segment.line(to: head)
                stroke(segment, color: color)
            }
            drawHead(at: head, color: color)
        }

        cacheWalls(scale: scale)
        if let wallImage { context.draw(wallImage, in: layout.bounds) }
        drawStart(at: layout.center(of: playback.solver.startIndex))
        drawFinish(at: layout.center(of: playback.solver.endIndex), solved: playback.phase == .solved)

        if playback.phase == .solved, !reducedMotion, playback.solvedElapsed < 1 {
            let progress = CGFloat(playback.solvedElapsed)
            let radius = layout.cellSize * (0.35 + progress * 1.5)
            let center = layout.center(of: playback.solver.endIndex)
            let ring = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius,
                                                 width: radius * 2, height: radius * 2))
            ring.lineWidth = max(1, layout.cellSize * 0.06 * (1 - progress))
            theme.solution.withAlphaComponent((1 - progress) * 0.7).setStroke()
            ring.stroke()
        }
        if let footer = layout.footer { drawFooter(in: footer, playback: playback, round: round) }
        if playback.phase == .solved, !reducedMotion, playback.solvedElapsed > MazeScreensaverView.solutionPause - 0.5 {
            let alpha = min(1, (playback.solvedElapsed - (MazeScreensaverView.solutionPause - 0.5)) / 0.5)
            theme.background.withAlphaComponent(alpha).setFill()
            layout.bounds.fill()
        }
    }

    private func updatePaths(_ playback: MazePlayback) {
        guard revision != playback.revision else { return }
        revision = playback.revision
        let indices = playback.settledPath
        settledPath = path(through: indices)
        settledEnd = indices.last
        solutionPath = path(through: playback.solutionPath)
        while pebbleCount < playback.backtrackedCells.count {
            let center = layout.center(of: playback.backtrackedCells[pebbleCount])
            let size = layout.cellSize * 0.17
            pebbles.appendRoundedRect(NSRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size),
                                      xRadius: size * 0.3, yRadius: size * 0.3)
            pebbleCount += 1
        }
    }

    private func path(through indices: [Int]) -> NSBezierPath {
        let path = NSBezierPath()
        for (offset, index) in indices.enumerated() {
            let point = layout.center(of: index)
            if offset == 0 { path.move(to: point) } else { path.line(to: point) }
        }
        return path
    }

    private func stroke(_ path: NSBezierPath, color: NSColor) {
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = layout.cellSize * 0.46
        color.withAlphaComponent(0.08).setStroke()
        path.stroke()
        path.lineWidth = layout.cellSize * 0.23
        color.setStroke()
        path.stroke()
    }

    private func headPosition(_ playback: MazePlayback) -> NSPoint? {
        guard let from = playback.headFrom, let to = playback.headTo else {
            return playback.exploringPath.last.map { layout.center(of: $0) }
        }
        let a = layout.center(of: from)
        let b = layout.center(of: to)
        let t = CGFloat(playback.progress)
        return NSPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private func drawHead(at point: NSPoint, color: NSColor) {
        let radius = layout.cellSize * 0.18
        color.withAlphaComponent(0.2).setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)).fill()
        NSColor.white.setFill()
        let core = radius * 0.55
        NSBezierPath(ovalIn: NSRect(x: point.x - core, y: point.y - core, width: core * 2, height: core * 2)).fill()
    }

    private func drawStart(at point: NSPoint) {
        let radius = layout.cellSize * 0.23
        let rect = NSRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        theme.background.setFill()
        NSBezierPath(ovalIn: rect).fill()
        let ring = NSBezierPath(ovalIn: rect)
        ring.lineWidth = max(1, layout.cellSize * 0.065)
        theme.active.setStroke()
        ring.stroke()
        theme.active.setFill()
        NSBezierPath(ovalIn: rect.insetBy(dx: radius * 0.65, dy: radius * 0.65)).fill()
    }

    private func drawFinish(at point: NSPoint, solved: Bool) {
        let size = layout.cellSize * 0.5
        let rect = NSRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: size * 0.14, yRadius: size * 0.14).addClip()
        for row in 0..<4 {
            for col in 0..<4 {
                let light = solved ? theme.solution : NSColor(calibratedWhite: 0.95, alpha: 1)
                ((row + col) % 2 == 0 ? light : theme.background).setFill()
                NSRect(x: rect.minX + CGFloat(col) * size / 4,
                       y: rect.minY + CGFloat(row) * size / 4, width: size / 4, height: size / 4).fill()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawFooter(in rect: NSRect, playback: MazePlayback, round: Int) {
        let solved = playback.phase == .solved
        let title = solved ? "PATH FOUND" : "FINDING A WAY"
        let detail = solved ? "\(max(0, playback.solutionPath.count - 1)) steps home" : "\(playback.visitedCount) / \(grid.count) cells explored"
        let caption = "\(title)   ·   \(detail)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .medium),
            .foregroundColor: theme.text.withAlphaComponent(0.65)
        ]
        caption.draw(at: NSPoint(x: rect.minX, y: rect.minY + 8), withAttributes: attributes)
        let counter = "MAZE \(String(format: "%02d", round))"
        let width = counter.size(withAttributes: attributes).width
        counter.draw(at: NSPoint(x: rect.maxX - width, y: rect.minY + 8), withAttributes: attributes)
        let track = NSRect(x: rect.minX, y: rect.maxY - 1, width: rect.width, height: 1)
        theme.wall.withAlphaComponent(0.5).setFill()
        track.fill()
        let progress = solved ? 1 : CGFloat(playback.visitedCount) / CGFloat(grid.count)
        (solved ? theme.solution : theme.active).withAlphaComponent(0.65).setFill()
        NSRect(x: track.minX, y: track.minY, width: track.width * progress, height: 1).fill()
    }

    private func cacheWalls(scale: CGFloat) {
        let scale = min(max(1, scale), sqrt(16_000_000 / (layout.bounds.width * layout.bounds.height)))
        guard wallImage == nil || wallScale != scale else { return }
        wallScale = scale
        let width = max(1, Int(ceil(layout.bounds.width * scale)))
        let height = max(1, Int(ceil(layout.bounds.height * scale)))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -layout.bounds.minX, y: -layout.bounds.minY)
        context.setStrokeColor(theme.wall.cgColor)
        context.setLineWidth(layout.wallThickness)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        let path = CGMutablePath()
        func line(_ a: CGPoint, _ b: CGPoint) { path.move(to: a); path.addLine(to: b) }
        for row in 0..<grid.rows {
            for col in 0..<grid.cols {
                let cell = grid.cell(at: row * grid.cols + col)
                let x = layout.origin.x + CGFloat(col) * layout.cellSize
                let y = layout.origin.y + CGFloat(grid.rows - row) * layout.cellSize
                let size = layout.cellSize
                if cell.north { line(CGPoint(x: x, y: y), CGPoint(x: x + size, y: y)) }
                if cell.west { line(CGPoint(x: x, y: y), CGPoint(x: x, y: y - size)) }
                if row == grid.rows - 1 && cell.south { line(CGPoint(x: x, y: y - size), CGPoint(x: x + size, y: y - size)) }
                if col == grid.cols - 1 && cell.east { line(CGPoint(x: x + size, y: y), CGPoint(x: x + size, y: y - size)) }
            }
        }
        context.addPath(path)
        context.strokePath()
        wallImage = context.makeImage()
        #if VERIFY
        verificationWallCacheBuilds += 1
        #endif
    }
}
