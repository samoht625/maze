import ScreenSaver
import AppKit
import QuartzCore

// MARK: - Parameters
private enum Speed {
    case slow
    case medium
    case fast
    case extraFast
}

private enum SolveStrategy {
    case random
    case left
    case right
}

private struct Parameters {
    static let cellSize: CGFloat = 30.0
    static var wallThickness: CGFloat { max(1.0, round(cellSize * 0.20)) }
    static let speed: Speed = .fast
    static let showDebugOverlay: Bool = false
    static func randomSolveStrategy() -> SolveStrategy {
        return [.left, .right].randomElement()!
    }
    static var stepsPerFrame: Int {
        switch speed {
        case .slow: return 1
        case .medium: return 6
        case .fast: return 8  // Reduced from 12 for smoother animation
        case .extraFast: return 24
        }
    }
    static let postSolvePauseSeconds: TimeInterval = 3.0
    static var stepDuration: TimeInterval {
        switch speed {
        case .slow: return 0.08
        case .medium: return 0.05
        case .fast: return 0.035  // Increased from 0.025 for slightly slower, smoother speed
        case .extraFast: return 0.012
        }
    }
    
    // Colors
    static let backgroundColor = NSColor.black
    static let wallColor = NSColor.white
    static let startColor = NSColor.systemGreen
    static let endColor = NSColor.systemRed
    static let exploringColor = NSColor.cyan
    static let backtrackColor = NSColor.orange
    static let solutionColor = NSColor(red: 0xF5/255.0, green: 0xD5/255.0, blue: 0x47/255.0, alpha: 1.0)  // Citrine Glow
}

// MARK: - Cell Model
private struct Cell {
    var north: Bool = true
    var south: Bool = true
    var east: Bool = true
    var west: Bool = true
    var visited: Bool = false
    
    mutating func removeWall(_ direction: Direction) {
        switch direction {
        case .north: north = false
        case .south: south = false
        case .east: east = false
        case .west: west = false
        }
    }
}

private enum Direction: CaseIterable {
    case north, south, east, west
    
    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        }
    }
    
    func turnedLeft() -> Direction {
        switch self {
        case .north: return .west
        case .west: return .south
        case .south: return .east
        case .east: return .north
        }
    }
    
    func turnedRight() -> Direction {
        switch self {
        case .north: return .east
        case .east: return .south
        case .south: return .west
        case .west: return .north
        }
    }
}

// MARK: - Maze Grid
private class MazeGrid {
    let rows: Int
    let cols: Int
    private var cells: [Cell]
    
    init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        self.cells = Array(repeating: Cell(), count: rows * cols)
    }
    
    func cellAt(row: Int, col: Int) -> Cell {
        guard isValid(row: row, col: col) else { return Cell() }
        return cells[row * cols + col]
    }
    
    func setCell(_ cell: Cell, row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        cells[row * cols + col] = cell
    }
    
    func isValid(row: Int, col: Int) -> Bool {
        return row >= 0 && row < rows && col >= 0 && col < cols
    }
    
    func index(row: Int, col: Int) -> Int {
        return row * cols + col
    }
    
    func rowCol(for index: Int) -> (row: Int, col: Int) {
        return (index / cols, index % cols)
    }
    
    func neighbor(index: Int, direction: Direction) -> Int? {
        let (row, col) = rowCol(for: index)
        let (nRow, nCol) = neighborCoords(row: row, col: col, direction: direction)
        guard isValid(row: nRow, col: nCol) else { return nil }
        return self.index(row: nRow, col: nCol)
    }
    
    private func neighborCoords(row: Int, col: Int, direction: Direction) -> (row: Int, col: Int) {
        switch direction {
        case .north: return (row - 1, col)
        case .south: return (row + 1, col)
        case .east: return (row, col + 1)
        case .west: return (row, col - 1)
        }
    }
    
    func removeWall(from fromIndex: Int, to toIndex: Int) {
        let (fromRow, fromCol) = rowCol(for: fromIndex)
        let (toRow, toCol) = rowCol(for: toIndex)
        
        var fromCell = cellAt(row: fromRow, col: fromCol)
        var toCell = cellAt(row: toRow, col: toCol)
        
        if toRow < fromRow {
            fromCell.removeWall(.north)
            toCell.removeWall(.south)
        } else if toRow > fromRow {
            fromCell.removeWall(.south)
            toCell.removeWall(.north)
        } else if toCol < fromCol {
            fromCell.removeWall(.west)
            toCell.removeWall(.east)
        } else if toCol > fromCol {
            fromCell.removeWall(.east)
            toCell.removeWall(.west)
        }
        
        setCell(fromCell, row: fromRow, col: fromCol)
        setCell(toCell, row: toRow, col: toCol)
    }
    
    func markVisited(index: Int) {
        let (row, col) = rowCol(for: index)
        var cell = cellAt(row: row, col: col)
        cell.visited = true
        setCell(cell, row: row, col: col)
    }
    
    func clearVisited() {
        for i in 0..<cells.count {
            let (row, col) = rowCol(for: i)
            var cell = cellAt(row: row, col: col)
            cell.visited = false
            setCell(cell, row: row, col: col)
        }
    }
}

// MARK: - Maze Generator
private class MazeGenerator {
    private var grid: MazeGrid
    private var stack: [Int] = []
    private var currentIndex: Int = 0
    private var isComplete = false
    
    init(grid: MazeGrid) {
        self.grid = grid
        // Start at top-left
        currentIndex = 0
        self.grid.markVisited(index: currentIndex)
        stack.append(currentIndex)
    }
    
    func step() -> Int? {
        guard !isComplete else { return nil }
        
        // Get unvisited neighbors
        let unvisitedNeighbors = Direction.allCases.compactMap { dir -> (direction: Direction, index: Int)? in
            guard let neighborIdx = grid.neighbor(index: currentIndex, direction: dir) else { return nil }
            let (row, col) = grid.rowCol(for: neighborIdx)
            let cell = grid.cellAt(row: row, col: col)
            if !cell.visited {
                return (dir, neighborIdx)
            }
            return nil
        }
        
        if let (_, neighborIdx) = unvisitedNeighbors.randomElement() {
            // Carve passage
            self.grid.removeWall(from: currentIndex, to: neighborIdx)
            self.grid.markVisited(index: neighborIdx)
            stack.append(neighborIdx)
            currentIndex = neighborIdx
            return neighborIdx
        } else if !stack.isEmpty {
            // Backtrack
            stack.removeLast()
            if !stack.isEmpty {
                currentIndex = stack.last!
            }
            return nil
        } else {
            // Generation complete
            isComplete = true
            return nil
        }
    }
    
    var completed: Bool {
        return isComplete
    }
}

// MARK: - Maze Solver
private class MazeSolver {
    private var grid: MazeGrid
    private var stack: [Int] = []
    private var visited: Set<Int> = []
    private var parent: [Int: Int] = [:]
    private var isComplete = false
    private var solutionPath: [Int] = []
    private let strategy: SolveStrategy
    
    let startIndex: Int
    let endIndex: Int
    
    init(grid: MazeGrid, startIndex: Int, endIndex: Int, strategy: SolveStrategy) {
        self.grid = grid
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.strategy = strategy
        self.grid.clearVisited()
        stack.append(startIndex)
        visited.insert(startIndex)
    }
    
    // Helper: Find the two farthest-apart connected cells using BFS
    static func findFarthestEndpoints(grid: MazeGrid) -> (start: Int, end: Int) {
        // Start BFS from top-left corner
        let start = 0
        var queue: [(index: Int, distance: Int)] = [(start, 0)]
        var visited: Set<Int> = [start]
        var farthest = start
        var maxDistance = 0
        
        // First BFS: find farthest cell from start
        while !queue.isEmpty {
            let (current, distance) = queue.removeFirst()
            if distance > maxDistance {
                maxDistance = distance
                farthest = current
            }
            
            // Check all neighbors
            for direction in Direction.allCases {
                guard let neighborIdx = grid.neighbor(index: current, direction: direction) else { continue }
                if visited.contains(neighborIdx) { continue }
                
                // Check if passage exists
                let (row, col) = grid.rowCol(for: current)
                let cell = grid.cellAt(row: row, col: col)
                let hasPassage: Bool
                switch direction {
                case .north: hasPassage = !cell.north
                case .south: hasPassage = !cell.south
                case .east: hasPassage = !cell.east
                case .west: hasPassage = !cell.west
                }
                
                if hasPassage {
                    visited.insert(neighborIdx)
                    queue.append((neighborIdx, distance + 1))
                }
            }
        }
        
        // Second BFS: find farthest cell from the first farthest
        let end1 = farthest
        queue = [(end1, 0)]
        visited = [end1]
        farthest = end1
        maxDistance = 0
        
        while !queue.isEmpty {
            let (current, distance) = queue.removeFirst()
            if distance > maxDistance {
                maxDistance = distance
                farthest = current
            }
            
            for direction in Direction.allCases {
                guard let neighborIdx = grid.neighbor(index: current, direction: direction) else { continue }
                if visited.contains(neighborIdx) { continue }
                
                let (row, col) = grid.rowCol(for: current)
                let cell = grid.cellAt(row: row, col: col)
                let hasPassage: Bool
                switch direction {
                case .north: hasPassage = !cell.north
                case .south: hasPassage = !cell.south
                case .east: hasPassage = !cell.east
                case .west: hasPassage = !cell.west
                }
                
                if hasPassage {
                    visited.insert(neighborIdx)
                    queue.append((neighborIdx, distance + 1))
                }
            }
        }
        
        return (start: end1, end: farthest)
    }
    
    func step() -> SolverStep? {
        guard !isComplete else { return nil }
        
        guard let current = stack.last else {
            isComplete = true
            return nil
        }
        
        if current == endIndex {
            // Found solution, reconstruct path
            var sol = [current]
            var node = current
            while let parentNode = parent[node] {
                sol.append(parentNode)
                node = parentNode
            }
            solutionPath = sol.reversed()
            isComplete = true
            return .solved(path: solutionPath)
        }
        
        // Explore neighbors based on strategy
        let dirs: [Direction]
        // Determine forward heading relative to parent (for LEFT/RIGHT strategies)
        let forward: Direction = {
            if let p = parent[current] {
                let (pr, pc) = self.grid.rowCol(for: p)
                let (cr, cc) = self.grid.rowCol(for: current)
                if cr < pr { return .north }
                if cr > pr { return .south }
                if cc > pc { return .east }
                if cc < pc { return .west }
            }
            // If no parent, bias initial heading roughly toward end cell to look intentional
            let (er, ec) = self.grid.rowCol(for: endIndex)
            let (cr, cc) = self.grid.rowCol(for: current)
            let dr = er - cr
            let dc = ec - cc
            if abs(dc) >= abs(dr) { return dc >= 0 ? .east : .west }
            return dr >= 0 ? .south : .north
        }()
        switch strategy {
        case .random:
            dirs = Direction.allCases.shuffled()
        case .left:
            // Left-hand rule: left, straight, right, back
            dirs = [forward.turnedLeft(), forward, forward.turnedRight(), forward.opposite]
        case .right:
            // Right-hand rule: right, straight, left, back
            dirs = [forward.turnedRight(), forward, forward.turnedLeft(), forward.opposite]
        }
        
        for direction in dirs {
            guard let neighborIdx = self.grid.neighbor(index: current, direction: direction) else { continue }
            
            // Check if passage exists in current cell's wall
            let (row, col) = self.grid.rowCol(for: current)
            let cell = self.grid.cellAt(row: row, col: col)
            let hasPassage: Bool
            switch direction {
            case .north: hasPassage = !cell.north
            case .south: hasPassage = !cell.south
            case .east: hasPassage = !cell.east
            case .west: hasPassage = !cell.west
            }
            
            if hasPassage && !visited.contains(neighborIdx) {
                visited.insert(neighborIdx)
                parent[neighborIdx] = current
                stack.append(neighborIdx)
                return .visit(cell: neighborIdx)
            }
        }
        
        // Dead end: pop and backtrack one step
        let backtracked = stack.removeLast()
        if stack.isEmpty { isComplete = true }
        return .backtrack(from: backtracked)
    }
    
    var completed: Bool {
        return isComplete
    }
    
    func getSolutionPath() -> [Int] {
        return solutionPath
    }
}

private enum SolverStep {
    case visit(cell: Int)
    case backtrack(from: Int)
    case solved(path: [Int])
}

// MARK: - State Machine
private enum ScreensaverState {
    case generating
    case solving
    case solved(since: Date)
}

// MARK: - Maze Screensaver View
@objc(MazeScreensaverView)
final class MazeScreensaverView: ScreenSaverView {
    private var grid: MazeGrid?
    private var generator: MazeGenerator?
    private var solver: MazeSolver?
    private var state: ScreensaverState = .generating
    
    private var exploringPath: [Int] = []
    private var backtrackPath: Set<Int> = []
    private var solutionPath: [Int] = []
    
    // Dynamic colors per run
    private var activePathColor: NSColor = Parameters.exploringColor
    private var failedPathColor: NSColor = Parameters.backtrackColor
    
    // Store a random color for each backtracked pebble
    private var pebbleColors: [Int: NSColor] = [:]
    
    private var lastBounds: NSRect = .zero
    private var cachedWallPath: NSBezierPath?
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    private var animProgress: CGFloat = 1.0
    private var currentHeadFrom: Int?
    private var currentHeadTo: Int?
    private var currentIsBacktrack: Bool = false
    
    // Pebble color palette with 85% opacity
    private static let pebbleColorPalette: [NSColor] = [
        NSColor(red: 0xC5/255.0, green: 0xC7/255.0, blue: 0xC9/255.0, alpha: 0.85),  // Silver Mist
        NSColor(red: 0xA2/255.0, green: 0xA5/255.0, blue: 0xA6/255.0, alpha: 0.85),  // River Stone
        NSColor(red: 0x9F/255.0, green: 0xC9/255.0, blue: 0xC4/255.0, alpha: 0.85),  // Robin's Egg
        NSColor(red: 0xB6/255.0, green: 0xA3/255.0, blue: 0x8A/255.0, alpha: 0.85),  // Driftwood
        NSColor(red: 0x8C/255.0, green: 0x75/255.0, blue: 0x66/255.0, alpha: 0.85)   // Clay Brown
    ]
    
    private func randomPebbleColor() -> NSColor {
        return Self.pebbleColorPalette.randomElement() ?? Self.pebbleColorPalette[0]
    }
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 120.0  // 120 FPS for smoother animation
        wantsLayer = true
        
        lastBounds = bounds
        initializeMaze()
    }
    
    override func startAnimation() {
        super.startAnimation()
        // Reset timing to avoid a large dt on first frame and force an initial draw
        lastFrameTime = CACurrentMediaTime()
        setNeedsDisplay(bounds)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 120.0  // 120 FPS for smoother animation
        wantsLayer = true
        lastBounds = bounds
        initializeMaze()
    }
    
    private func initializeMaze() {
        // Reset animation head state and timing
        animProgress = 1.0
        currentHeadFrom = nil
        currentHeadTo = nil
        currentIsBacktrack = false
        lastFrameTime = CACurrentMediaTime()
        let cols = Int(bounds.width / Parameters.cellSize)
        let rows = Int(bounds.height / Parameters.cellSize)
        
        // Ensure minimum size
        var targetCols = cols
        var targetRows = rows
        if cols <= 10 || rows <= 10 {
            print("⚠️ Bounds too small: \(bounds.width) × \(bounds.height), cols: \(cols), rows: \(rows)")
            targetCols = max(cols, 50)
            targetRows = max(rows, 50)
        }
        
        print("Maze size: \(targetCols) cols × \(targetRows) rows = \(targetCols * targetRows) cells")
        print("Bounds: \(bounds.width) × \(bounds.height)")
        
        let newGrid = MazeGrid(rows: targetRows, cols: targetCols)
        grid = newGrid
        generator = MazeGenerator(grid: newGrid)
        state = .generating
        exploringPath = []
        backtrackPath = []
        solutionPath = []
        cachedWallPath = nil
        
        // Pick random primary color for the session (boosted saturation)
        let primaryColorChoices: [NSColor] = [
            NSColor(red: 1.0, green: 0.45, blue: 0.25, alpha: 1.0),      // Coral Beam (more vibrant)
            NSColor(red: 1.0, green: 0.20, blue: 0.50, alpha: 1.0),      // Cerise Pop (more vivid)
            NSColor(red: 0.15, green: 0.70, blue: 1.0, alpha: 1.0),      // Azure Pulse (brighter blue)
            NSColor(red: 0.40, green: 1.0, blue: 0.45, alpha: 1.0),      // Verdant Mint (more electric)
            NSColor(red: 0.80, green: 0.20, blue: 1.0, alpha: 1.0)       // Plum Energy (more vivid purple)
        ]
        activePathColor = primaryColorChoices.randomElement() ?? primaryColorChoices[0]
        
        // Clear pebble colors for new maze
        pebbleColors = [:]
        
        // Generate maze fully off the main thread (as fast as possible)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let gen = self.generator else { return }
            while !gen.completed {
                _ = gen.step()
            }
            // Compute farthest endpoints off the main thread too
            guard let g = self.grid else { return }
            var (startIdx, endIdx) = MazeSolver.findFarthestEndpoints(grid: g)
            // Randomize which endpoint is start vs end so the final square isn't biased
            if Bool.random() {
                swap(&startIdx, &endIdx)
            }
            DispatchQueue.main.async {
                self.solver = MazeSolver(grid: g, startIndex: startIdx, endIndex: endIdx, strategy: Parameters.randomSolveStrategy())
                self.state = .solving
                self.exploringPath = [startIdx]
                self.backtrackPath = []
                self.cachedWallPath = nil
                self.setNeedsDisplay(self.bounds)
            }
        }
        // Ensure we render at least the initial grid immediately
        self.setNeedsDisplay(self.bounds)
    }
    
    override func animateOneFrame() {
        // Time delta for smooth, time-accurate interpolation
        let now = CACurrentMediaTime()
        var dt = max(0.0, now - lastFrameTime)
        lastFrameTime = now
        // Cap to avoid pathological catch-up but keep time-accurate progression
        dt = min(dt, 0.25)
        // Check if bounds changed
        if bounds != lastBounds {
            lastBounds = bounds
            initializeMaze()
            setNeedsDisplay(bounds)
            return
        }
        
        switch state {
        case .generating:
            // Background thread is generating; nothing to do on the main thread here
            break
            
        case .solving:
            guard let solv = solver else { return }
            
            // Consume dt and advance at a fixed time rate independent of frame timing.
            // Limit the number of segment completions per frame to keep CPU in check.
            var remaining = dt
            var segmentsAdvanced = 0
            while remaining > 0 && segmentsAdvanced < Parameters.stepsPerFrame {
                if animProgress < 1.0 {
                    let timeToFinish = Parameters.stepDuration * CFTimeInterval(1.0 - animProgress)
                    if remaining >= timeToFinish {
                        animProgress = 1.0
                        remaining -= timeToFinish
                        // After finishing interpolation, request the next solver step
                        if let step = solv.step() {
                            switch step {
                            case .visit(let cell):
                                let fromIdx = exploringPath.last ?? cell
                                exploringPath.append(cell)
                                currentHeadFrom = fromIdx
                                currentHeadTo = cell
                                currentIsBacktrack = false
                                animProgress = 0.0
                                segmentsAdvanced += 1
                                
                            case .backtrack(let from):
                                if let idx = exploringPath.lastIndex(of: from) {
                                    exploringPath.removeSubrange(idx...)
                                }
                                backtrackPath.insert(from)
                                // Assign a random color to this pebble
                                pebbleColors[from] = randomPebbleColor()
                                if let toIdx = exploringPath.last {
                                    currentHeadFrom = from
                                    currentHeadTo = toIdx
                                    currentIsBacktrack = true
                                    animProgress = 0.0
                                } else {
                                    currentHeadFrom = nil
                                    currentHeadTo = nil
                                    currentIsBacktrack = true
                                    animProgress = 1.0
                                }
                                segmentsAdvanced += 1
                                
                            case .solved(let path):
                                solutionPath = path
                                state = .solved(since: Date())
                                exploringPath = []
                                remaining = 0
                            }
                        } else if solv.completed {
                            if !solv.getSolutionPath().isEmpty {
                                solutionPath = solv.getSolutionPath()
                                state = .solved(since: Date())
                                exploringPath = []
                            } else {
                                print("⚠️ No solution found")
                                state = .solved(since: Date())
                            }
                            remaining = 0
                        }
                    } else {
                        // Not enough time to finish current segment; interpolate and end
                        animProgress = min(1.0, animProgress + CGFloat(remaining / Parameters.stepDuration))
                        remaining = 0
                    }
                } else {
                    // No active interpolation, request next step immediately if time remains
                    if let step = solv.step() {
                        switch step {
                        case .visit(let cell):
                            let fromIdx = exploringPath.last ?? cell
                            exploringPath.append(cell)
                            currentHeadFrom = fromIdx
                            currentHeadTo = cell
                            currentIsBacktrack = false
                            animProgress = 0.0
                            segmentsAdvanced += 1
                        case .backtrack(let from):
                            if let idx = exploringPath.lastIndex(of: from) {
                                exploringPath.removeSubrange(idx...)
                            }
                            backtrackPath.insert(from)
                            // Assign a random color to this pebble
                            pebbleColors[from] = randomPebbleColor()
                            if let toIdx = exploringPath.last {
                                currentHeadFrom = from
                                currentHeadTo = toIdx
                                currentIsBacktrack = true
                                animProgress = 0.0
                            } else {
                                currentHeadFrom = nil
                                currentHeadTo = nil
                                currentIsBacktrack = true
                                animProgress = 1.0
                            }
                            segmentsAdvanced += 1
                        case .solved(let path):
                            solutionPath = path
                            state = .solved(since: Date())
                            exploringPath = []
                            remaining = 0
                        }
                    } else {
                        remaining = 0
                    }
                }
            }
            
        case .solved(let since):
            let elapsed = Date().timeIntervalSince(since)
            if elapsed >= Parameters.postSolvePauseSeconds {
                // Reset and generate new maze
                initializeMaze()
            }
        }
        
        setNeedsDisplay(bounds)
    }
    
    override func draw(_ rect: NSRect) {
        // Fill background
        Parameters.backgroundColor.setFill()
        rect.fill()
        
        guard let g = grid else { return }
        
        // Ensure valid bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        NSGraphicsContext.current?.shouldAntialias = true
        let t = Parameters.wallThickness
        
        // Helpers for inner rect and centers
        let inset: CGFloat = t / 2.0
        func innerRect(forRow row: Int, col: Int) -> NSRect {
            return NSRect(
                x: CGFloat(col) * Parameters.cellSize + inset,
                y: CGFloat(row) * Parameters.cellSize + inset,
                width: Parameters.cellSize - t,
                height: Parameters.cellSize - t
            )
        }
        func centerPoint(forRow row: Int, col: Int) -> NSPoint {
            return NSPoint(
                x: CGFloat(col) * Parameters.cellSize + Parameters.cellSize / 2.0,
                y: CGFloat(row) * Parameters.cellSize + Parameters.cellSize / 2.0
            )
        }
        func centerPoint(forIndex index: Int) -> NSPoint {
            let (r, c) = g.rowCol(for: index)
            return centerPoint(forRow: r, col: c)
        }
        let tubeThickness = max(1.0, (Parameters.cellSize - t) * 0.7)
        // Pellets match the tube width for consistency
        let pelletDiameter: CGFloat = tubeThickness
        
        if !solutionPath.isEmpty {
            // Draw solution as a smooth tube across centers
            let path = NSBezierPath()
            path.lineWidth = tubeThickness
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            var started = false
            for index in solutionPath {
                let (row, col) = g.rowCol(for: index)
                let c = centerPoint(forRow: row, col: col)
                if !started {
                    path.move(to: c)
                    started = true
                } else {
                    path.line(to: c)
                }
            }
            Parameters.solutionColor.setStroke()
            path.stroke()
        } else {
            // Draw backtracked cells as rounded square pebbles centered in the cell
            for index in backtrackPath {
                let (row, col) = g.rowCol(for: index)
                let c = centerPoint(forRow: row, col: col)
                let pelletRect = NSRect(
                    x: c.x - pelletDiameter / 2.0,
                    y: c.y - pelletDiameter / 2.0,
                    width: pelletDiameter,
                    height: pelletDiameter
                )
                // Use the assigned color for this pebble, or a default if somehow missing
                let pebbleColor = pebbleColors[index] ?? randomPebbleColor()
                pebbleColor.setFill()
                // Rounded square with corner radius ~25% of size for visible roundedness
                let roundedSquare = NSBezierPath(roundedRect: pelletRect, xRadius: pelletDiameter * 0.25, yRadius: pelletDiameter * 0.25)
                roundedSquare.fill()
            }
            
            // Draw exploring path as a smooth tube with interpolated head and easing
            if !exploringPath.isEmpty {
                let path = NSBezierPath()
                path.lineWidth = tubeThickness
                path.lineJoinStyle = .round
                path.lineCapStyle = .round
                var started = false
                // Draw complete segments
                for i in 0..<exploringPath.count {
                    let idx = exploringPath[i]
                    let c = centerPoint(forIndex: idx)
                    if !started { path.move(to: c); started = true } else { path.line(to: c) }
                }
                // Extend to interpolated head
                if let fromIdx = currentHeadFrom, let toIdx = currentHeadTo, animProgress < 1.0 {
                    let a = centerPoint(forIndex: fromIdx)
                    let b = centerPoint(forIndex: toIdx)
                    // ease-in-out cubic for smoother feel
                    let t2 = animProgress * animProgress
                    let t3 = t2 * animProgress
                    let ease = 3*t2 - 2*t3
                    let head = NSPoint(
                        x: a.x + (b.x - a.x) * ease,
                        y: a.y + (b.y - a.y) * ease
                    )
                    if started { path.line(to: head) } else { path.move(to: head) }
                }
                activePathColor.setStroke()
                path.stroke()
            }
            
            // Animate backtrack contraction: render a rounded square pebble at the retracting head
            if currentIsBacktrack, let fromIdx = currentHeadFrom, let toIdx = currentHeadTo, animProgress < 1.0 {
                let a = centerPoint(forIndex: fromIdx)
                let b = centerPoint(forIndex: toIdx)
                let t2 = animProgress * animProgress
                let t3 = t2 * animProgress
                let ease = 3*t2 - 2*t3
                let head = NSPoint(
                    x: b.x + (a.x - b.x) * (1.0 - ease),
                    y: b.y + (a.y - b.y) * (1.0 - ease)
                )
                let dotRect = NSRect(
                    x: head.x - pelletDiameter / 2.0,
                    y: head.y - pelletDiameter / 2.0,
                    width: pelletDiameter,
                    height: pelletDiameter
                )
                // Use the color assigned to this pebble
                let pebbleColor = pebbleColors[fromIdx] ?? randomPebbleColor()
                pebbleColor.setFill()
                let roundedSquare = NSBezierPath(roundedRect: dotRect, xRadius: pelletDiameter * 0.25, yRadius: pelletDiameter * 0.25)
                roundedSquare.fill()
            }
        }
        
        // Stroke walls with rounded joins/caps to smooth corners (cached)
        if cachedWallPath == nil {
            let path = NSBezierPath()
            path.lineWidth = t
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            for row in 0..<g.rows {
                for col in 0..<g.cols {
                    let cell = g.cellAt(row: row, col: col)
                    let x = CGFloat(col) * Parameters.cellSize
                    let y = CGFloat(row) * Parameters.cellSize
                    if cell.north { path.move(to: NSPoint(x: x, y: y)); path.line(to: NSPoint(x: x + Parameters.cellSize, y: y)) }
                    if cell.west { path.move(to: NSPoint(x: x, y: y)); path.line(to: NSPoint(x: x, y: y + Parameters.cellSize)) }
                    if row == g.rows - 1 && cell.south { path.move(to: NSPoint(x: x, y: y + Parameters.cellSize)); path.line(to: NSPoint(x: x + Parameters.cellSize, y: y + Parameters.cellSize)) }
                    if col == g.cols - 1 && cell.east { path.move(to: NSPoint(x: x + Parameters.cellSize, y: y)); path.line(to: NSPoint(x: x + Parameters.cellSize, y: y + Parameters.cellSize)) }
                }
            }
            cachedWallPath = path
        }
        if let cachedWallPath {
            Parameters.wallColor.setStroke()
            cachedWallPath.stroke()
        }
        
        // Helper function to draw checkered flag pattern
        func drawCheckeredFlag(in rect: NSRect, rows: Int = 4, cols: Int = 4) {
            let squareWidth = rect.width / CGFloat(cols)
            let squareHeight = rect.height / CGFloat(rows)
            
            for row in 0..<rows {
                for col in 0..<cols {
                    // Alternate black and white in checkerboard pattern
                    let isBlack = (row + col) % 2 == 0
                    let color = isBlack ? NSColor.black : NSColor.white
                    color.setFill()
                    
                    let squareRect = NSRect(
                        x: rect.origin.x + CGFloat(col) * squareWidth,
                        y: rect.origin.y + CGFloat(row) * squareHeight,
                        width: squareWidth,
                        height: squareHeight
                    )
                    NSBezierPath(rect: squareRect).fill()
                }
            }
        }
        
        // Draw start and finish markers on top (checkered flag pattern)
        if let startIdx = solver?.startIndex {
            let (row, col) = g.rowCol(for: startIdx)
            let r = innerRect(forRow: row, col: col)
            
            // Create rounded rect clipping path
            let roundedRect = NSBezierPath(roundedRect: r, xRadius: r.width * 0.25, yRadius: r.height * 0.25)
            NSGraphicsContext.saveGraphicsState()
            roundedRect.addClip()
            drawCheckeredFlag(in: r)
            NSGraphicsContext.restoreGraphicsState()
        }
        
        if let endIdx = solver?.endIndex {
            let (row, col) = g.rowCol(for: endIdx)
            let r = innerRect(forRow: row, col: col)
            
            // Create rounded rect clipping path
            let roundedRect = NSBezierPath(roundedRect: r, xRadius: r.width * 0.25, yRadius: r.height * 0.25)
            NSGraphicsContext.saveGraphicsState()
            roundedRect.addClip()
            drawCheckeredFlag(in: r)
            NSGraphicsContext.restoreGraphicsState()
        }

        // Debug overlay (always visible, top-left)
        if Parameters.showDebugOverlay {
            let overlay = "v1.0.12 bright"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: NSColor.yellow
            ]
            let size = overlay.size(withAttributes: attrs)
            let p = NSPoint(x: bounds.minX + 15, y: bounds.maxY - size.height - 15)
            
            // Draw bright background so it's unmissable
            let bgRect = NSRect(x: p.x - 8, y: p.y - 4, width: size.width + 16, height: size.height + 8)
            NSColor.red.withAlphaComponent(0.8).setFill()
            NSBezierPath(rect: bgRect).fill()
            
            overlay.draw(at: p, withAttributes: attrs)
        }
    }
    
    override var hasConfigureSheet: Bool {
        return false
    }
    
    override var configureSheet: NSWindow? {
        return nil
    }
}
