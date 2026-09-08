import XCTest
@testable import MazeCore

extension XCTestCase {
    func generatedMaze(rows: Int, cols: Int, seed: UInt64 = 0,
                       file: StaticString = #filePath, line: UInt = #line) -> MazeGrid {
        let grid = MazeGrid(rows: rows, cols: cols)
        let generator = MazeGenerator(grid: grid, seed: seed)
        for _ in 0..<(grid.count * 2) where !generator.completed {
            generator.step()
        }
        XCTAssertTrue(generator.completed, file: file, line: line)
        return grid
    }

    func maze(rows: Int, cols: Int, passages: [(Int, Int)]) -> MazeGrid {
        let grid = MazeGrid(rows: rows, cols: cols)
        for (from, to) in passages {
            grid.removeWall(from: from, to: to)
        }
        return grid
    }

    func cells(in grid: MazeGrid) -> [Cell] {
        (0..<grid.count).map { grid.cell(at: $0) }
    }

    func hasWall(_ cell: Cell, _ direction: Direction) -> Bool {
        switch direction {
        case .north: return cell.north
        case .south: return cell.south
        case .east: return cell.east
        case .west: return cell.west
        }
    }

    func distances(in grid: MazeGrid, from start: Int) -> [Int] {
        var result = Array(repeating: -1, count: grid.count)
        result[start] = 0
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            for direction in Direction.allCases {
                guard !hasWall(grid.cell(at: current), direction),
                      let next = grid.neighbor(index: current, direction: direction),
                      result[next] == -1 else { continue }
                result[next] = result[current] + 1
                queue.append(next)
            }
        }
        return result
    }

    func solve(_ solver: MazeSolver, file: StaticString = #filePath,
               line: UInt = #line) -> [SolverStep] {
        var events: [SolverStep] = []
        for _ in 0..<(solver.grid.count * 2 + 1) {
            if let step = solver.step() { events.append(step) }
            if solver.completed { break }
        }
        XCTAssertTrue(solver.completed, file: file, line: line)
        XCTAssertNil(solver.step(), file: file, line: line)
        return events
    }

    func assertValidPath(_ path: [Int], in grid: MazeGrid, from start: Int, to end: Int,
                         file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(path.first, start, file: file, line: line)
        XCTAssertEqual(path.last, end, file: file, line: line)
        XCTAssertEqual(Set(path).count, path.count, file: file, line: line)
        XCTAssertTrue(path.allSatisfy { (0..<grid.count).contains($0) }, file: file, line: line)
        for (from, to) in zip(path, path.dropFirst()) {
            XCTAssertTrue(Direction.allCases.contains {
                grid.neighbor(index: from, direction: $0) == to &&
                    grid.hasPassage(from: from, direction: $0)
            }, "No passage between \(from) and \(to)", file: file, line: line)
        }
    }

    func playback(grid: MazeGrid, start: Int = 0, end: Int? = nil,
                  strategy: SolveStrategy = .left, seed: UInt64 = 0) -> MazePlayback {
        MazePlayback(solver: MazeSolver(grid: grid, startIndex: start,
                                       endIndex: end ?? grid.count - 1,
                                       strategy: strategy, seed: seed))
    }

    func branchingMaze() -> MazeGrid {
        maze(rows: 2, cols: 3, passages: [(3, 0), (0, 1), (3, 4), (4, 5), (5, 2)])
    }

    func assertSamePlayback(_ actual: MazePlayback, _ expected: MazePlayback,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.exploringPath, expected.exploringPath, file: file, line: line)
        XCTAssertEqual(actual.settledPath, expected.settledPath, file: file, line: line)
        XCTAssertEqual(actual.backtrackedCells, expected.backtrackedCells, file: file, line: line)
        XCTAssertEqual(actual.solutionPath, expected.solutionPath, file: file, line: line)
        XCTAssertEqual(actual.headFrom, expected.headFrom, file: file, line: line)
        XCTAssertEqual(actual.headTo, expected.headTo, file: file, line: line)
        XCTAssertEqual(actual.isBacktracking, expected.isBacktracking, file: file, line: line)
        XCTAssertEqual(actual.progress, expected.progress, accuracy: 1e-10, file: file, line: line)
        XCTAssertEqual(actual.phase, expected.phase, file: file, line: line)
        XCTAssertEqual(actual.solvedElapsed, expected.solvedElapsed, accuracy: 1e-10,
                       file: file, line: line)
        XCTAssertEqual(actual.revision, expected.revision, file: file, line: line)
        XCTAssertEqual(actual.stepsTaken, expected.stepsTaken, file: file, line: line)
        XCTAssertEqual(actual.visitedCount, expected.visitedCount, file: file, line: line)
        XCTAssertEqual(actual.solver.completed, expected.solver.completed, file: file, line: line)
        XCTAssertEqual(actual.solver.solutionPath, expected.solver.solutionPath, file: file, line: line)
    }
}
