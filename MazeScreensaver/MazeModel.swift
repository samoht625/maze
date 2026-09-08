enum Direction: CaseIterable {
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
        case .south: return .east
        case .east: return .north
        case .west: return .south
        }
    }

    func turnedRight() -> Direction {
        switch self {
        case .north: return .east
        case .south: return .west
        case .east: return .south
        case .west: return .north
        }
    }
}

enum SolveStrategy: CaseIterable {
    case left, right, random
}

struct Cell: Equatable {
    private(set) var north = true
    private(set) var south = true
    private(set) var east = true
    private(set) var west = true

    fileprivate func hasWall(_ direction: Direction) -> Bool {
        switch direction {
        case .north: return north
        case .south: return south
        case .east: return east
        case .west: return west
        }
    }

    fileprivate mutating func removeWall(_ direction: Direction) {
        switch direction {
        case .north: north = false
        case .south: south = false
        case .east: east = false
        case .west: west = false
        }
    }
}

final class MazeGrid {
    let rows: Int
    let cols: Int
    private var cells: [Cell]

    var count: Int { cells.count }

    init(rows: Int, cols: Int) {
        self.rows = max(1, rows)
        self.cols = max(1, cols)
        cells = Array(repeating: Cell(), count: self.rows * self.cols)
    }

    func cell(at index: Int) -> Cell {
        guard cells.indices.contains(index) else { return Cell() }
        return cells[index]
    }

    func rowCol(for index: Int) -> (row: Int, col: Int) {
        (index / cols, index % cols)
    }

    func neighbor(index: Int, direction: Direction) -> Int? {
        guard cells.indices.contains(index) else { return nil }
        let (row, col) = rowCol(for: index)
        switch direction {
        case .north: return row > 0 ? index - cols : nil
        case .south: return row + 1 < rows ? index + cols : nil
        case .east: return col + 1 < cols ? index + 1 : nil
        case .west: return col > 0 ? index - 1 : nil
        }
    }

    func hasPassage(from index: Int, direction: Direction) -> Bool {
        guard neighbor(index: index, direction: direction) != nil else { return false }
        return !cells[index].hasWall(direction)
    }

    func removeWall(from fromIndex: Int, to toIndex: Int) {
        guard cells.indices.contains(fromIndex), cells.indices.contains(toIndex),
              let direction = Direction.allCases.first(where: {
                  neighbor(index: fromIndex, direction: $0) == toIndex
              }) else { return }
        cells[fromIndex].removeWall(direction)
        cells[toIndex].removeWall(direction.opposite)
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64 supports every seed, including zero.
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

final class MazeGenerator {
    private let grid: MazeGrid
    private var random: SeededRandomNumberGenerator
    private var visited: [Bool]
    private var stack = [0]
    private(set) var completed = false

    init(grid: MazeGrid, seed: UInt64 = UInt64.random(in: .min ... .max)) {
        self.grid = grid
        random = SeededRandomNumberGenerator(seed: seed)
        visited = Array(repeating: false, count: grid.count)
        visited[0] = true
    }

    @discardableResult
    func step() -> Int? {
        guard !completed, let current = stack.last else { return nil }
        let neighbors = Direction.allCases.compactMap { direction -> Int? in
            guard let next = grid.neighbor(index: current, direction: direction),
                  !visited[next] else { return nil }
            return next
        }
        if let next = neighbors.randomElement(using: &random) {
            grid.removeWall(from: current, to: next)
            visited[next] = true
            stack.append(next)
            return next
        }
        stack.removeLast()
        completed = stack.isEmpty
        return nil
    }
}

enum SolverStep: Equatable {
    case visit(cell: Int)
    case backtrack(from: Int)
    case solved(path: [Int])
}

final class MazeSolver {
    let grid: MazeGrid
    let startIndex: Int
    let endIndex: Int
    private let strategy: SolveStrategy
    private var random: SeededRandomNumberGenerator
    private var visited: [Bool]
    private var stack: [Int] = []
    private(set) var completed = false
    private(set) var solutionPath: [Int] = []
    private(set) var visitedCount = 0

    init(grid: MazeGrid, startIndex: Int, endIndex: Int, strategy: SolveStrategy,
         seed: UInt64 = UInt64.random(in: .min ... .max)) {
        self.grid = grid
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.strategy = strategy
        random = SeededRandomNumberGenerator(seed: seed)
        visited = Array(repeating: false, count: grid.count)
        guard (0..<grid.count).contains(startIndex), (0..<grid.count).contains(endIndex) else {
            completed = true
            return
        }
        stack.append(startIndex)
        visited[startIndex] = true
        visitedCount = 1
    }

    static func findFarthestEndpoints(grid: MazeGrid) -> (start: Int, end: Int) {
        // Two BFS passes find the diameter of a generated (tree) maze.
        let start = farthestCell(in: grid, from: 0)
        return (start, farthestCell(in: grid, from: start))
    }

    private static func farthestCell(in grid: MazeGrid, from start: Int) -> Int {
        var distances = Array(repeating: -1, count: grid.count)
        distances[start] = 0
        var queue = [start]
        queue.reserveCapacity(grid.count)
        var head = 0
        var farthest = start
        while head < queue.count {
            let current = queue[head]
            head += 1
            for direction in Direction.allCases {
                guard grid.hasPassage(from: current, direction: direction),
                      let next = grid.neighbor(index: current, direction: direction),
                      distances[next] == -1 else { continue }
                distances[next] = distances[current] + 1
                queue.append(next)
                if distances[next] > distances[farthest] {
                    farthest = next
                }
            }
        }
        return farthest
    }

    func step() -> SolverStep? {
        guard !completed, let current = stack.last else { return nil }
        if current == endIndex {
            solutionPath = stack
            completed = true
            return .solved(path: solutionPath)
        }

        let forward = heading(at: current)
        let directions: [Direction]
        switch strategy {
        case .left:
            directions = [forward.turnedLeft(), forward, forward.turnedRight(), forward.opposite]
        case .right:
            directions = [forward.turnedRight(), forward, forward.turnedLeft(), forward.opposite]
        case .random:
            directions = Direction.allCases.shuffled(using: &random)
        }
        for direction in directions {
            guard grid.hasPassage(from: current, direction: direction),
                  let next = grid.neighbor(index: current, direction: direction),
                  !visited[next] else { continue }
            visited[next] = true
            visitedCount += 1
            stack.append(next)
            return .visit(cell: next)
        }

        let from = stack.removeLast()
        completed = stack.isEmpty
        return .backtrack(from: from)
    }

    private func heading(at current: Int) -> Direction {
        let (row, col) = grid.rowCol(for: current)
        if stack.count > 1 {
            let (parentRow, parentCol) = grid.rowCol(for: stack[stack.count - 2])
            if row < parentRow { return .north }
            if row > parentRow { return .south }
            return col > parentCol ? .east : .west
        }
        let (endRow, endCol) = grid.rowCol(for: endIndex)
        if abs(endCol - col) >= abs(endRow - row) {
            return endCol >= col ? .east : .west
        }
        return endRow >= row ? .south : .north
    }
}
