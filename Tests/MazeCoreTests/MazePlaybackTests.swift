import XCTest
@testable import MazeCore

final class MazePlaybackTests: XCTestCase {
    func testInitialStateAndForwardInterpolationExcludeDestinationGeometry() {
        let playback = playback(grid: generatedMaze(rows: 1, cols: 3))
        XCTAssertEqual(playback.phase, .solving)
        XCTAssertEqual(playback.exploringPath, [0])
        XCTAssertEqual(playback.settledPath, [0])
        XCTAssertTrue(playback.backtrackedCells.isEmpty)
        XCTAssertTrue(playback.solutionPath.isEmpty)
        XCTAssertNil(playback.headFrom)
        XCTAssertNil(playback.headTo)
        XCTAssertFalse(playback.isBacktracking)
        XCTAssertEqual(playback.progress, 1)
        XCTAssertEqual(playback.revision, 0)
        XCTAssertEqual(playback.stepsTaken, 0)
        XCTAssertEqual(playback.visitedCount, 1)
        XCTAssertEqual(playback.solvedElapsed, 0)

        playback.advance(by: 0.05, stepDuration: 0.2)
        XCTAssertEqual(playback.exploringPath, [0, 1])
        XCTAssertEqual(playback.settledPath, [0])
        XCTAssertEqual(playback.headFrom, 0)
        XCTAssertEqual(playback.headTo, 1)
        XCTAssertEqual(playback.progress, 0.25, accuracy: 1e-12)
        XCTAssertEqual(playback.stepsTaken, 1)
        XCTAssertEqual(playback.visitedCount, 2)
        XCTAssertEqual(playback.revision, 1)

        playback.advance(by: 0.05, stepDuration: 0.2)
        XCTAssertEqual(playback.progress, 0.5, accuracy: 1e-12)
        XCTAssertEqual(playback.settledPath, [0])
        XCTAssertEqual(playback.stepsTaken, 1)
        XCTAssertEqual(playback.visitedCount, 2)
        XCTAssertEqual(playback.revision, 1)

        playback.advance(by: 0.1, stepDuration: 0.2)
        XCTAssertEqual(playback.exploringPath, [0, 1, 2])
        XCTAssertEqual(playback.settledPath, [0, 1])
        XCTAssertEqual(playback.headFrom, 1)
        XCTAssertEqual(playback.headTo, 2)
        XCTAssertEqual(playback.progress, 0, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 2)
        XCTAssertEqual(playback.stepsTaken, 2)
        XCTAssertEqual(playback.visitedCount, 3)
    }

    func testSolutionWaitsForFinalHeadAndClearsTransition() {
        let playback = playback(grid: generatedMaze(rows: 1, cols: 2))
        playback.advance(by: 0.099, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .solving)
        XCTAssertFalse(playback.solver.completed)
        XCTAssertTrue(playback.solutionPath.isEmpty)
        XCTAssertEqual(playback.solvedElapsed, 0)
        XCTAssertEqual(playback.progress, 0.99, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 1)

        playback.advance(by: 0.001, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .solved)
        XCTAssertTrue(playback.solver.completed)
        XCTAssertEqual(playback.solutionPath, [0, 1])
        XCTAssertTrue(playback.exploringPath.isEmpty)
        XCTAssertTrue(playback.settledPath.isEmpty)
        XCTAssertNil(playback.headFrom)
        XCTAssertNil(playback.headTo)
        XCTAssertFalse(playback.isBacktracking)
        XCTAssertEqual(playback.progress, 1)
        XCTAssertEqual(playback.revision, 2)
        XCTAssertEqual(playback.stepsTaken, 2)
        XCTAssertEqual(playback.solvedElapsed, 0, accuracy: 1e-12)
    }

    func testBacktrackingPopsGeometryBeforeInterpolationAndAppendsUniqueCells() {
        let playback = playback(grid: branchingMaze(), start: 3, end: 5)
        playback.advance(by: 0.2, stepDuration: 0.1)
        XCTAssertEqual(playback.exploringPath, [3, 0])
        XCTAssertEqual(playback.settledPath, [3, 0])
        XCTAssertEqual(playback.backtrackedCells, [1])
        XCTAssertEqual(playback.headFrom, 1)
        XCTAssertEqual(playback.headTo, 0)
        XCTAssertTrue(playback.isBacktracking)
        XCTAssertEqual(playback.progress, 0, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 3)
        XCTAssertEqual(playback.stepsTaken, 3)
        XCTAssertEqual(playback.visitedCount, 3)

        playback.advance(by: 0.05, stepDuration: 0.1)
        XCTAssertEqual(playback.progress, 0.5, accuracy: 1e-12)
        XCTAssertEqual(playback.settledPath, [3, 0])
        XCTAssertEqual(playback.backtrackedCells, [1])
        XCTAssertEqual(playback.revision, 3)

        playback.advance(by: 0.05, stepDuration: 0.1)
        XCTAssertEqual(playback.exploringPath, [3])
        XCTAssertEqual(playback.settledPath, [3])
        XCTAssertEqual(playback.backtrackedCells, [1, 0])
        XCTAssertEqual(playback.headFrom, 0)
        XCTAssertEqual(playback.headTo, 3)
        XCTAssertTrue(playback.isBacktracking)
        XCTAssertEqual(playback.progress, 0, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 4)

        playback.advance(by: 0.2, stepDuration: 0.1)
        XCTAssertEqual(playback.exploringPath, [3, 4, 5])
        XCTAssertEqual(playback.settledPath, [3, 4])
        XCTAssertEqual(playback.backtrackedCells, [1, 0])
        XCTAssertFalse(playback.isBacktracking)
        XCTAssertEqual(playback.revision, 6)

        playback.advance(by: 0.1, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .solved)
        XCTAssertEqual(playback.solutionPath, [3, 4, 5])
        XCTAssertEqual(playback.backtrackedCells, [1, 0])
        XCTAssertEqual(Set(playback.backtrackedCells).count, playback.backtrackedCells.count)
        XCTAssertEqual(playback.revision, 7)
        XCTAssertEqual(playback.stepsTaken, 7)
        XCTAssertEqual(playback.visitedCount, 5)
    }

    func testRevisionKeyedPathCacheStaysCurrentAtExactSegmentBoundaries() {
        let scenarios: [(MazePlayback, PlaybackPhase)] = [
            (playback(grid: generatedMaze(rows: 1, cols: 4)), .solved),
            (playback(grid: branchingMaze(), start: 3, end: 5), .solved),
            (playback(grid: maze(rows: 1, cols: 3, passages: [(0, 1)])), .failed),
            (playback(grid: MazeGrid(rows: 1, cols: 1)), .solved)
        ]
        for (playback, terminalPhase) in scenarios {
            var cachedRevision = playback.revision
            var cachedPath = playback.settledPath
            var cachedSolution = playback.solutionPath
            XCTAssertEqual(playback.progress, 1)
            XCTAssertEqual(cachedPath, playback.exploringPath)

            // Binary fractions land exactly on every fourth frame's segment boundary.
            for _ in 0..<32 {
                let previousRevision = playback.revision
                let previousSteps = playback.stepsTaken
                playback.advance(by: 0.03125, stepDuration: 0.125)
                if cachedRevision != playback.revision {
                    cachedRevision = playback.revision
                    cachedPath = playback.settledPath
                    cachedSolution = playback.solutionPath
                }
                XCTAssertEqual(cachedPath, playback.settledPath)
                XCTAssertEqual(cachedSolution, playback.solutionPath)
                if playback.progress == 1 {
                    XCTAssertEqual(cachedPath, playback.exploringPath)
                }
                if playback.stepsTaken == previousSteps {
                    XCTAssertEqual(playback.revision, previousRevision)
                }
            }
            XCTAssertEqual(playback.phase, terminalPhase)
            XCTAssertEqual(playback.progress, 1)
            XCTAssertTrue(cachedPath.isEmpty)
        }
    }

    func testSingleCellSolvesWithoutAnimatingAndKeepsEntireDelta() {
        let playback = playback(grid: generatedMaze(rows: 1, cols: 1))
        playback.advance(by: 0.125, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .solved)
        XCTAssertEqual(playback.solutionPath, [0])
        XCTAssertEqual(playback.solvedElapsed, 0.125)
        XCTAssertEqual(playback.progress, 1)
        XCTAssertNil(playback.headFrom)
        XCTAssertNil(playback.headTo)
        XCTAssertEqual(playback.revision, 1)
        XCTAssertEqual(playback.stepsTaken, 1)
        XCTAssertEqual(playback.visitedCount, 1)
    }

    func testFailureWaitsForBacktrackingAndKeepsLeftoverTime() {
        let grid = maze(rows: 1, cols: 3, passages: [(0, 1)])
        let playback = playback(grid: grid)
        playback.advance(by: 0.15, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .solving)
        XCTAssertTrue(playback.isBacktracking)
        XCTAssertEqual(playback.progress, 0.5, accuracy: 1e-12)
        XCTAssertEqual(playback.exploringPath, [0])
        XCTAssertEqual(playback.backtrackedCells, [1])
        XCTAssertEqual(playback.solvedElapsed, 0)

        playback.advance(by: 0.08, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .failed)
        XCTAssertTrue(playback.solver.completed)
        XCTAssertTrue(playback.solutionPath.isEmpty)
        XCTAssertTrue(playback.exploringPath.isEmpty)
        XCTAssertTrue(playback.settledPath.isEmpty)
        XCTAssertEqual(playback.backtrackedCells, [1, 0])
        XCTAssertNil(playback.headFrom)
        XCTAssertNil(playback.headTo)
        XCTAssertFalse(playback.isBacktracking)
        XCTAssertEqual(playback.progress, 1)
        XCTAssertEqual(playback.revision, 3)
        XCTAssertEqual(playback.stepsTaken, 3)
        XCTAssertEqual(playback.visitedCount, 2)
        XCTAssertEqual(playback.solvedElapsed, 0.03, accuracy: 1e-12)
        playback.advance(by: 0.1, stepDuration: 0.1)
        XCTAssertEqual(playback.solvedElapsed, 0.13, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 3)
    }

    func testInvalidSolverTransitionsToFailureWithoutAnimation() {
        let playback = playback(grid: MazeGrid(rows: 1, cols: 1), start: -1)
        XCTAssertTrue(playback.exploringPath.isEmpty)
        playback.advance(by: 0.125, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .failed)
        XCTAssertEqual(playback.solvedElapsed, 0.125)
        XCTAssertEqual(playback.stepsTaken, 0)
        XCTAssertEqual(playback.visitedCount, 0)
        XCTAssertEqual(playback.revision, 1)
        XCTAssertEqual(playback.progress, 1)
    }

    func testThirtySixtyAndOneHundredTwentyFPSHaveIdenticalState() {
        let grid = generatedMaze(rows: 6, cols: 7, seed: 43)
        let endpoints = MazeSolver.findFarthestEndpoints(grid: grid)
        for strategy in SolveStrategy.allCases {
            let reference = playback(grid: grid, start: endpoints.start, end: endpoints.end,
                                     strategy: strategy, seed: 91)
            for _ in 0..<4 { reference.advance(by: 0.25, stepDuration: 0.035) }
            for fps in [30, 60, 120] {
                let candidate = playback(grid: grid, start: endpoints.start, end: endpoints.end,
                                         strategy: strategy, seed: 91)
                for _ in 0..<fps {
                    candidate.advance(by: 1 / Double(fps), stepDuration: 0.035)
                }
                assertSamePlayback(candidate, reference)
            }
        }
    }

    func testIrregularFrameTimesMatchDuringBacktrackingAndAfterSolving() {
        let grid = branchingMaze()
        let schedules = [
            ([0.25, 0.04], [0.013, 0.047, 0.02, 0.17, 0.005, 0.015, 0.02], 29),
            ([0.25, 0.25, 0.07], [0.013, 0.047, 0.02, 0.17, 0.005, 0.015, 0.1, 0.2], 57)
        ]
        for (coarse, irregular, frames) in schedules {
            let reference = playback(grid: grid, start: 3, end: 5)
            let jittered = playback(grid: grid, start: 3, end: 5)
            let fine = playback(grid: grid, start: 3, end: 5)
            for delta in coarse { reference.advance(by: delta, stepDuration: 0.08) }
            for delta in irregular { jittered.advance(by: delta, stepDuration: 0.08) }
            for _ in 0..<frames { fine.advance(by: 0.01, stepDuration: 0.08) }
            assertSamePlayback(jittered, reference)
            assertSamePlayback(fine, reference)
            if frames == 29 {
                XCTAssertEqual(reference.phase, .solving)
                XCTAssertTrue(reference.isBacktracking)
                XCTAssertEqual(reference.progress, 0.625, accuracy: 1e-12)
            } else {
                XCTAssertEqual(reference.phase, .solved)
                XCTAssertEqual(reference.solvedElapsed, 0.09, accuracy: 1e-12)
            }
        }
    }

    func testLargeDeltaIsCappedInSolvingAndSolvedPhases() {
        let grid = branchingMaze()
        let reference = playback(grid: grid, start: 3, end: 5)
        let stalled = playback(grid: grid, start: 3, end: 5)
        reference.advance(by: 0.25, stepDuration: 0.08)
        stalled.advance(by: 60, stepDuration: 0.08)
        assertSamePlayback(stalled, reference)

        let single = playback(grid: MazeGrid(rows: 1, cols: 1))
        single.advance(by: 60, stepDuration: 0.1)
        XCTAssertEqual(single.phase, .solved)
        XCTAssertEqual(single.solvedElapsed, 0.25)
        single.advance(by: 60, stepDuration: 0.1)
        XCTAssertEqual(single.solvedElapsed, 0.5)
    }

    func testInvalidTimeInputsDoNotAdvanceOrCorruptProgress() {
        let grid = generatedMaze(rows: 1, cols: 3)
        let playback = playback(grid: grid)
        let untouched = self.playback(grid: grid)
        for delta in [0, -1, Double.nan, Double.infinity, -Double.infinity] {
            playback.advance(by: delta, stepDuration: 0.1)
            assertSamePlayback(playback, untouched)
        }
        for duration in [0, -0.1, Double.nan, Double.infinity, -Double.infinity] {
            playback.advance(by: 0.1, stepDuration: duration)
            assertSamePlayback(playback, untouched)
        }
        playback.advance(by: 0.05, stepDuration: 0.1)
        XCTAssertEqual(playback.progress, 0.5, accuracy: 1e-12)
        XCTAssertEqual(playback.stepsTaken, 1)
    }

    func testSolvedElapsedDrivesRestartTimingAndNewPlaybackResetsIt() {
        let grid = generatedMaze(rows: 1, cols: 2)
        let playback = playback(grid: grid)
        playback.advance(by: 0.16, stepDuration: 0.1)
        XCTAssertEqual(playback.phase, .solved)
        XCTAssertEqual(playback.solvedElapsed, 0.06, accuracy: 1e-12)
        playback.advance(by: 0.24, stepDuration: 0.1)
        XCTAssertEqual(playback.solvedElapsed, 0.3, accuracy: 1e-12)
        for _ in 0..<10 {
            let elapsed = playback.solvedElapsed
            playback.advance(by: 0.25, stepDuration: 0.1)
            XCTAssertGreaterThan(playback.solvedElapsed, elapsed)
        }
        XCTAssertEqual(playback.solvedElapsed, 2.8, accuracy: 1e-12)
        XCTAssertLessThan(playback.solvedElapsed, 3)
        playback.advance(by: 0.21, stepDuration: 0.1)
        XCTAssertGreaterThanOrEqual(playback.solvedElapsed, 3)
        XCTAssertEqual(playback.solvedElapsed, 3.01, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 2)
        XCTAssertEqual(playback.stepsTaken, 2)
        XCTAssertEqual(playback.visitedCount, 2)

        let restarted = self.playback(grid: grid)
        XCTAssertEqual(restarted.phase, .solving)
        XCTAssertEqual(restarted.solvedElapsed, 0)
        XCTAssertEqual(restarted.revision, 0)
        XCTAssertEqual(restarted.stepsTaken, 0)
        XCTAssertEqual(restarted.visitedCount, 1)
        XCTAssertEqual(restarted.exploringPath, [0])
        XCTAssertTrue(restarted.solutionPath.isEmpty)
        XCTAssertTrue(restarted.backtrackedCells.isEmpty)
    }

    func testTerminalElapsedIgnoresInvalidDeltasAndDoesNotNeedStepDuration() {
        let playback = playback(grid: MazeGrid(rows: 1, cols: 1))
        playback.advance(by: 0.1, stepDuration: 0.1)
        for delta in [0, -1, Double.nan, Double.infinity, -Double.infinity] {
            playback.advance(by: delta, stepDuration: 0.1)
            XCTAssertEqual(playback.solvedElapsed, 0.1)
        }
        playback.advance(by: 0.1, stepDuration: .nan)
        XCTAssertEqual(playback.solvedElapsed, 0.2, accuracy: 1e-12)
        XCTAssertEqual(playback.revision, 1)
    }

    func testPlaybackStrategiesFinishWithBoundedProgressAndAppendOnlyBacktracks() {
        let grid = generatedMaze(rows: 8, cols: 11, seed: 321)
        let snapshot = cells(in: grid)
        let endpoints = MazeSolver.findFarthestEndpoints(grid: grid)
        for strategy in SolveStrategy.allCases {
            let playback = playback(grid: grid, start: endpoints.start, end: endpoints.end,
                                    strategy: strategy, seed: 123)
            var previousBacktracks: [Int] = []
            for _ in 0..<(grid.count * 8) where playback.phase == .solving {
                playback.advance(by: 0.01, stepDuration: 0.03)
                XCTAssertTrue((0...1).contains(playback.progress))
                XCTAssertTrue(playback.backtrackedCells.starts(with: previousBacktracks))
                XCTAssertEqual(Set(playback.backtrackedCells).count, playback.backtrackedCells.count)
                previousBacktracks = playback.backtrackedCells
            }
            XCTAssertEqual(playback.phase, .solved)
            assertValidPath(playback.solutionPath, in: grid, from: endpoints.start, to: endpoints.end)
            XCTAssertEqual(cells(in: grid), snapshot)
        }
    }
}
