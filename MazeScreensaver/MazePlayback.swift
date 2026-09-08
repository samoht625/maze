enum PlaybackPhase {
    case solving, solved, failed
}

final class MazePlayback {
    let solver: MazeSolver
    private(set) var exploringPath: [Int]
    private(set) var backtrackedCells: [Int] = []
    private(set) var solutionPath: [Int] = []
    private(set) var headFrom: Int?
    private(set) var headTo: Int?
    private(set) var isBacktracking = false
    private(set) var progress = 1.0
    private(set) var phase: PlaybackPhase = .solving
    private(set) var solvedElapsed = 0.0
    private(set) var revision = 0
    private(set) var stepsTaken = 0
    private var backtracked: [Bool]

    var visitedCount: Int { solver.visitedCount }

    var settledPath: [Int] {
        if progress < 1, !isBacktracking {
            return Array(exploringPath.dropLast())
        }
        return exploringPath
    }

    init(solver: MazeSolver) {
        self.solver = solver
        exploringPath = solver.visitedCount > 0 ? [solver.startIndex] : []
        backtracked = Array(repeating: false, count: solver.grid.count)
    }

    func advance(by delta: Double, stepDuration: Double) {
        guard delta.isFinite, delta > 0 else { return }
        var remaining = min(delta, 0.25)
        if phase != .solving {
            solvedElapsed += remaining
            return
        }
        guard stepDuration.isFinite, stepDuration > 0 else { return }

        while phase == .solving {
            if progress < 1 {
                let timeToFinish = (1 - progress) * stepDuration
                // Roundoff at segment boundaries must not depend on frame rate.
                if remaining + stepDuration * 1e-12 < timeToFinish {
                    progress = min(1, progress + remaining / stepDuration)
                    return
                }
                remaining = max(0, remaining - timeToFinish)
                progress = 1
            }
            transition(solver.step())
        }
        solvedElapsed += remaining
    }

    private func transition(_ step: SolverStep?) {
        revision += 1
        headFrom = nil
        headTo = nil
        isBacktracking = false
        progress = 1
        if step != nil { stepsTaken += 1 }

        switch step {
        case .visit(let cell):
            headFrom = exploringPath.last
            headTo = cell
            exploringPath.append(cell)
            progress = 0
        case .backtrack(let from):
            exploringPath.removeLast()
            if !backtracked[from] {
                backtracked[from] = true
                backtrackedCells.append(from)
            }
            if let to = exploringPath.last {
                headFrom = from
                headTo = to
                isBacktracking = true
                progress = 0
            } else {
                phase = .failed
            }
        case .solved(let path):
            solutionPath = path
            exploringPath.removeAll(keepingCapacity: true)
            phase = .solved
        case nil:
            solutionPath = solver.solutionPath
            exploringPath.removeAll(keepingCapacity: true)
            phase = solutionPath.isEmpty ? .failed : .solved
        }
    }
}
