import XCTest
@testable import MazeCore

final class MazeModelTests: XCTestCase {
    func testDirectionRotations() {
        let cases: [(Direction, Direction, Direction, Direction)] = [
            (.north, .south, .west, .east),
            (.south, .north, .east, .west),
            (.east, .west, .north, .south),
            (.west, .east, .south, .north)
        ]
        XCTAssertEqual(Direction.allCases.count, 4)
        XCTAssertEqual(SolveStrategy.allCases.count, 3)
        for (direction, opposite, left, right) in cases {
            XCTAssertEqual(direction.opposite, opposite)
            XCTAssertEqual(direction.turnedLeft(), left)
            XCTAssertEqual(direction.turnedRight(), right)
            XCTAssertEqual(direction.opposite.opposite, direction)
            XCTAssertEqual(direction.turnedLeft().turnedRight(), direction)
            XCTAssertEqual(direction.turnedLeft().turnedLeft(), opposite)
        }
    }

    func testDimensionsClampToOneAndCellsStartClosed() {
        for (rows, cols) in [(0, 0), (-4, Int.min), (0, 7), (9, -2), (3, 5)] {
            let grid = MazeGrid(rows: rows, cols: cols)
            XCTAssertEqual(grid.rows, max(1, rows))
            XCTAssertEqual(grid.cols, max(1, cols))
            XCTAssertEqual(grid.count, max(1, rows) * max(1, cols))
            XCTAssertTrue(cells(in: grid).allSatisfy { $0 == Cell() })
        }
    }

    func testCoordinatesNeighborsAndInvalidIndices() {
        let grid = MazeGrid(rows: 3, cols: 4)
        for index in 0..<grid.count {
            let (row, col) = grid.rowCol(for: index)
            XCTAssertEqual(row, index / 4)
            XCTAssertEqual(col, index % 4)
            XCTAssertEqual(grid.neighbor(index: index, direction: .north), row > 0 ? index - 4 : nil)
            XCTAssertEqual(grid.neighbor(index: index, direction: .south), row < 2 ? index + 4 : nil)
            XCTAssertEqual(grid.neighbor(index: index, direction: .west), col > 0 ? index - 1 : nil)
            XCTAssertEqual(grid.neighbor(index: index, direction: .east), col < 3 ? index + 1 : nil)
        }
        for index in [-1, grid.count, Int.min, Int.max] {
            XCTAssertEqual(grid.cell(at: index), Cell())
            for direction in Direction.allCases {
                XCTAssertNil(grid.neighbor(index: index, direction: direction))
                XCTAssertFalse(grid.hasPassage(from: index, direction: direction))
            }
        }
    }

    func testWallRemovalIsReciprocalAndIdempotent() throws {
        for direction in Direction.allCases {
            let grid = MazeGrid(rows: 3, cols: 3)
            let next = try XCTUnwrap(grid.neighbor(index: 4, direction: direction))
            grid.removeWall(from: 4, to: next)
            for index in 0..<grid.count {
                for wall in Direction.allCases {
                    let removed = (index == 4 && wall == direction) ||
                        (index == next && wall == direction.opposite)
                    XCTAssertEqual(hasWall(grid.cell(at: index), wall), !removed)
                    XCTAssertEqual(grid.hasPassage(from: index, direction: wall), removed)
                }
            }
            let snapshot = cells(in: grid)
            grid.removeWall(from: next, to: 4)
            grid.removeWall(from: 4, to: next)
            XCTAssertEqual(cells(in: grid), snapshot)
        }
    }

    func testInvalidWallRemovalsLeaveGridUnchanged() {
        let grid = maze(rows: 3, cols: 3, passages: [(0, 1), (4, 7)])
        let snapshot = cells(in: grid)
        let invalid = [
            (0, 0), (0, 2), (0, 6), (0, 8), (2, 3), (2, 4),
            (-1, 0), (0, -1), (9, 0), (0, 9), (Int.min, 0), (0, Int.max)
        ]
        for (from, to) in invalid {
            grid.removeWall(from: from, to: to)
            grid.removeWall(from: to, to: from)
            XCTAssertEqual(cells(in: grid), snapshot, "Invalid removal: \(from), \(to)")
        }
    }

    func testSeededGenerationIsDeterministic() {
        for seed: UInt64 in [0, 1, 42, .max] {
            let first = generatedMaze(rows: 10, cols: 13, seed: seed)
            let second = generatedMaze(rows: 10, cols: 13, seed: seed)
            XCTAssertEqual(cells(in: first), cells(in: second))
        }
        XCTAssertNotEqual(cells(in: generatedMaze(rows: 10, cols: 13, seed: 0)),
                          cells(in: generatedMaze(rows: 10, cols: 13, seed: 1)))
    }

    func testGenerationCanPauseAndCompletedStepsDoNothing() {
        let grid = MazeGrid(rows: 6, cols: 6)
        let generator = MazeGenerator(grid: grid, seed: 81)
        for _ in 0..<17 { generator.step() }
        XCTAssertFalse(generator.completed)
        let paused = cells(in: grid)
        _ = MazeSolver.findFarthestEndpoints(grid: grid)
        XCTAssertEqual(cells(in: grid), paused)
        for _ in 0..<(grid.count * 2) where !generator.completed { generator.step() }
        XCTAssertTrue(generator.completed)
        let finished = cells(in: grid)
        XCTAssertEqual(finished, cells(in: generatedMaze(rows: 6, cols: 6, seed: 81)))
        for _ in 0..<5 { XCTAssertNil(generator.step()) }
        XCTAssertEqual(cells(in: grid), finished)
    }

    func testGeneratedMazesArePerfectConnectedAndReciprocal() {
        let sizes = [(1, 1), (1, 2), (2, 1), (1, 32), (32, 1), (2, 2), (3, 7), (10, 14), (25, 17)]
        for (rows, cols) in sizes {
            for seed: UInt64 in [0, 1, 42, .max] {
                let grid = generatedMaze(rows: rows, cols: cols, seed: seed)
                XCTAssertTrue(distances(in: grid, from: 0).allSatisfy { $0 >= 0 })
                var passages = 0
                for index in 0..<grid.count {
                    for direction in Direction.allCases {
                        let wall = hasWall(grid.cell(at: index), direction)
                        if let neighbor = grid.neighbor(index: index, direction: direction) {
                            XCTAssertEqual(wall, hasWall(grid.cell(at: neighbor), direction.opposite))
                            XCTAssertEqual(grid.hasPassage(from: index, direction: direction), !wall)
                            if !wall && (direction == .east || direction == .south) { passages += 1 }
                        } else {
                            XCTAssertTrue(wall)
                            XCTAssertFalse(grid.hasPassage(from: index, direction: direction))
                        }
                    }
                }
                XCTAssertEqual(passages, grid.count - 1, "\(rows)x\(cols), seed \(seed)")
            }
        }
    }

    func testFarthestEndpointsMatchExhaustiveDiameter() {
        for (rows, cols) in [(1, 1), (1, 21), (21, 1), (2, 2), (3, 7), (8, 9)] {
            for seed: UInt64 in [0, 7, 42, 1001] {
                let grid = generatedMaze(rows: rows, cols: cols, seed: seed)
                let snapshot = cells(in: grid)
                let endpoints = MazeSolver.findFarthestEndpoints(grid: grid)
                let diameter = (0..<grid.count).map { distances(in: grid, from: $0).max()! }.max()!
                XCTAssertEqual(distances(in: grid, from: endpoints.start)[endpoints.end], diameter)
                XCTAssertEqual(cells(in: grid), snapshot)
            }
        }
    }

    func testDiameterCanEndInsideGridInsteadOfAtCorners() {
        let path = [4, 1, 0, 3, 6, 7, 8, 5, 2]
        let grid = maze(rows: 3, cols: 3, passages: Array(zip(path, path.dropFirst())))
        let endpoints = MazeSolver.findFarthestEndpoints(grid: grid)
        XCTAssertEqual(endpoints.start, 2)
        XCTAssertEqual(endpoints.end, 4)
        XCTAssertEqual(distances(in: grid, from: endpoints.start)[endpoints.end], 8)
    }

    func testEveryStrategyTerminatesWithUniqueValidSolutionWithoutMutatingGrid() {
        for (rows, cols) in [(1, 1), (1, 31), (31, 1), (2, 2), (7, 9), (19, 29)] {
            for seed: UInt64 in [0, 42, .max] {
                let grid = generatedMaze(rows: rows, cols: cols, seed: seed)
                let snapshot = cells(in: grid)
                let (start, end) = MazeSolver.findFarthestEndpoints(grid: grid)
                for strategy in SolveStrategy.allCases {
                    let solver = MazeSolver(grid: grid, startIndex: start, endIndex: end,
                                            strategy: strategy, seed: seed)
                    XCTAssertEqual(solver.visitedCount, 1)
                    var seen: Set<Int> = [start]
                    var path = [start]
                    let events = solve(solver)
                    for event in events {
                        switch event {
                        case .visit(let cell):
                            XCTAssertTrue(seen.insert(cell).inserted)
                            path.append(cell)
                        case .backtrack(let from):
                            XCTAssertEqual(path.popLast(), from)
                        case .solved(let solution):
                            XCTAssertEqual(solution, path)
                        }
                    }
                    XCTAssertEqual(events.last, .solved(path: solver.solutionPath))
                    XCTAssertEqual(solver.visitedCount, seen.count)
                    XCTAssertLessThanOrEqual(solver.visitedCount, grid.count)
                    assertValidPath(solver.solutionPath, in: grid, from: start, to: end)
                    XCTAssertEqual(solver.solutionPath.count - 1, distances(in: grid, from: start)[end])
                    XCTAssertEqual(cells(in: grid), snapshot)
                }
            }
        }
    }

    func testLeftAndRightPreferencesKeepParentHeadingAfterBacktracking() {
        let grid = maze(rows: 3, cols: 3, passages: [
            (4, 1), (4, 5), (4, 7), (4, 3), (1, 0), (1, 2), (7, 6), (7, 8)
        ])
        let cases: [(SolveStrategy, [SolverStep])] = [
            (.left, [.visit(cell: 1), .visit(cell: 0), .backtrack(from: 0),
                     .visit(cell: 2), .backtrack(from: 2), .backtrack(from: 1),
                     .visit(cell: 5), .solved(path: [4, 5])]),
            (.right, [.visit(cell: 7), .visit(cell: 6), .backtrack(from: 6),
                      .visit(cell: 8), .backtrack(from: 8), .backtrack(from: 7),
                      .visit(cell: 5), .solved(path: [4, 5])])
        ]
        for (strategy, expected) in cases {
            for seed: UInt64 in [0, .max] {
                let solver = MazeSolver(grid: grid, startIndex: 4, endIndex: 5,
                                        strategy: strategy, seed: seed)
                XCTAssertEqual(solve(solver), expected)
                XCTAssertEqual(solver.visitedCount, 5)
            }
        }
    }

    func testRandomSolverEventsAreSeededAndIndependent() {
        let grid = generatedMaze(rows: 8, cols: 11, seed: 58)
        for seed: UInt64 in [0, 42, .max] {
            let first = MazeSolver(grid: grid, startIndex: 38, endIndex: 0, strategy: .random, seed: seed)
            let second = MazeSolver(grid: grid, startIndex: 38, endIndex: 0, strategy: .random, seed: seed)
            XCTAssertEqual(solve(first), solve(second))
            XCTAssertEqual(first.visitedCount, second.visitedCount)
        }
    }

    func testSameStartAndEndSolvesImmediately() {
        let grid = MazeGrid(rows: 3, cols: 3)
        for strategy in SolveStrategy.allCases {
            let solver = MazeSolver(grid: grid, startIndex: 4, endIndex: 4, strategy: strategy, seed: 0)
            XCTAssertEqual(solve(solver), [.solved(path: [4])])
            XCTAssertEqual(solver.solutionPath, [4])
            XCTAssertEqual(solver.visitedCount, 1)
        }
    }

    func testDisconnectedMazeTerminatesAfterVisitingOnlyReachableCells() {
        let grid = maze(rows: 3, cols: 3, passages: [(0, 1), (1, 2), (1, 4)])
        let snapshot = cells(in: grid)
        for strategy in SolveStrategy.allCases {
            let solver = MazeSolver(grid: grid, startIndex: 0, endIndex: 8, strategy: strategy, seed: 3)
            let events = solve(solver)
            XCTAssertEqual(events.count, 7)
            XCTAssertEqual(events.last, .backtrack(from: 0))
            XCTAssertEqual(solver.visitedCount, 4)
            XCTAssertTrue(solver.solutionPath.isEmpty)
            XCTAssertEqual(cells(in: grid), snapshot)
        }
    }

    func testCyclesDoNotCauseRevisitsOrPreventTermination() {
        let grid = maze(rows: 2, cols: 3, passages: [(0, 1), (1, 4), (4, 3), (3, 0)])
        for end in [4, 5] {
            for strategy in SolveStrategy.allCases {
                let solver = MazeSolver(grid: grid, startIndex: 0, endIndex: end,
                                        strategy: strategy, seed: 7)
                let visits = solve(solver).compactMap { event -> Int? in
                    if case .visit(let cell) = event { return cell }
                    return nil
                }
                XCTAssertEqual(Set(visits).count, visits.count)
                XCTAssertFalse(visits.contains(0))
                XCTAssertEqual(solver.visitedCount, visits.count + 1)
                if end == 4 {
                    assertValidPath(solver.solutionPath, in: grid, from: 0, to: end)
                } else {
                    XCTAssertTrue(solver.solutionPath.isEmpty)
                    XCTAssertEqual(solver.visitedCount, 4)
                }
            }
        }
    }

    func testInvalidSolverEndpointsCompleteWithoutAccessingCells() {
        let grid = MazeGrid(rows: 2, cols: 2)
        for (start, end) in [(-1, 0), (0, 4), (4, 0), (0, -1), (Int.min, Int.max)] {
            let solver = MazeSolver(grid: grid, startIndex: start, endIndex: end,
                                    strategy: .left, seed: 0)
            XCTAssertTrue(solver.completed)
            XCTAssertNil(solver.step())
            XCTAssertTrue(solver.solutionPath.isEmpty)
            XCTAssertEqual(solver.visitedCount, 0)
        }
    }
}
