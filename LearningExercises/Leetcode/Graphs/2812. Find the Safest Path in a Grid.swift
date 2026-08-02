/*

 2812. Find the Safest Path in a Grid

 You are given a 0-indexed 2D matrix grid of size n x n, where (r, c) represents:

 A cell containing a thief if grid[r][c] = 1
 An empty cell if grid[r][c] = 0
 You are initially positioned at cell (0, 0). In one move, you can move to any adjacent cell in the grid, including cells containing thieves.

 The safeness factor of a path on the grid is defined as the minimum manhattan distance from any cell in the path to any thief in the grid.

 Return the maximum safeness factor of all paths leading to cell (n - 1, n - 1).

 An adjacent cell of cell (r, c), is one of the cells (r, c + 1), (r, c - 1), (r + 1, c) and (r - 1, c) if it exists.

 The Manhattan distance between two cells (a, b) and (x, y) is equal to |a - x| + |b - y|, where |val| denotes the absolute value of val.

 https://leetcode.com/problems/find-the-safest-path-in-a-grid/

 */

import Collections

//Initial unoptimized solution
fileprivate class NaiveSolution {

    private struct Heaper: Comparable {
        let r: Int
        let c: Int
        let dist: Int
        let minDist: Int
        public static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs.minDist == rhs.minDist { return lhs.dist > rhs.dist }
            return lhs.minDist > rhs.minDist
        }
    }

    func maximumSafenessFactor(_ grid: [[Int]]) -> Int {
        let n = grid.count
        guard grid[0][0] != 1 && grid[n - 1][n - 1] != 1 else { return 0 }

        var newGrid = Array(repeating: Array(repeating: Int.max / 2, count: n), count: n)

        grid.indices.map { r in
            grid[r].indices.map { c in
                if grid[r][c] == 1 { BFSManhattanDistance(&newGrid, r, c, n) }
            }
        }

        var visited = Array(repeating: Array(repeating: Int.min / 2, count: n), count: n)
        var queue: Heap<Heaper> = [Heaper(r: 0, c: 0, dist: newGrid[0][0], minDist: newGrid[0][0])]
        while let cell = queue.popMin() {
            guard visited[cell.r][cell.c] < cell.minDist else { continue }
            visited[cell.r][cell.c] = cell.minDist

            if cell.r == n - 1 && cell.c == n - 1 { return cell.minDist }
            for delta in [[0, 1], [1, 0], [0, -1], [-1, 0]] {
                let newR = cell.r + delta[0], newC = cell.c + delta[1]
                guard 0 <= newR, newR < n, 0 <= newC, newC < n else { continue }

                let nextDist = newGrid[newR][newC]
                queue.insert(Heaper(r: newR, c: newC, dist: nextDist, minDist: min(nextDist, cell.minDist)))
            }

        }

        return 0
    }

    private func BFSManhattanDistance(_ grid: inout [[Int]],_ r: Int,_ c: Int,_ n: Int) {

        final class BFSQueue {
            var q = [(r: Int, c: Int)]()
        }

        var queue = BFSQueue()
        queue.q.append((r: r, c: c))
        while !queue.q.isEmpty {
            let newQueue = BFSQueue()

            for cell in queue.q {
                let distance = abs(cell.r - r) + abs(cell.c - c)
                guard grid[cell.r][cell.c] > distance else { continue }
                grid[cell.r][cell.c] = distance

                for delta in [[0, 1], [1, 0], [0, -1], [-1, 0]] {
                    let newR = cell.r + delta[0], newC = cell.c + delta[1]
                    guard 0 <= newR, newR < n, 0 <= newC, newC < n else { continue }
                    newQueue.q.append((r: newR, c: newC))
                }
            }

            queue = newQueue
        }
    }

}


//MARK: - Optimized Solution
//Saves significant time on BFS queries by processing them all at once
fileprivate class OptimizedSolution {

    private struct Heaper: Comparable {
        let r: Int
        let c: Int
        let dist: Int
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.dist > rhs.dist
        }
    }

    func maximumSafenessFactor(_ grid: [[Int]]) -> Int {
        guard grid[0][0] != 1 && grid.last!.last! != 1 else { return 0 }
        let n = grid.count

        var newGrid = Array(repeating: Array(repeating: Int.max / 2, count: n), count: n)

        final class BFSQueue {  var q = [(r: Int, c: Int)]() }
        var BFSqueue = BFSQueue()
        var depth = 0

        for r in grid.indices {
            for c in grid.indices {
                if grid[r][c] == 1 { BFSqueue.q.append((r: r, c: c)) }
            }
        }

        //BFS
        while !BFSqueue.q.isEmpty {
            let newQueue = BFSQueue()

            for cell in BFSqueue.q {
                guard newGrid[cell.r][cell.c] > depth else { continue }
                newGrid[cell.r][cell.c] = depth

                for delta in [[0, 1], [1, 0], [0, -1], [-1, 0]] {
                    let newR = cell.r + delta[0], newC = cell.c + delta[1]
                    guard 0 <= newR, newR < n, 0 <= newC, newC < n else { continue }
                    newQueue.q.append((r: newR, c: newC))
                }
            }

            depth += 1
            BFSqueue = newQueue
        }

        //Dijkstra's
        var visited = Array(repeating: Array(repeating: Int.min / 2, count: n), count: n)
        var queue: Heap<Heaper> = [Heaper(r: 0, c: 0, dist: newGrid[0][0])]
        while let cell = queue.popMin() {
            guard visited[cell.r][cell.c] < cell.dist else { continue }
            if cell.r == n - 1 && cell.c == n - 1 { return cell.dist }
            visited[cell.r][cell.c] = cell.dist

            for delta in [[0, 1], [1, 0], [0, -1], [-1, 0]] {
                let newR = cell.r + delta[0], newC = cell.c + delta[1]
                guard 0 <= newR, newR < n, 0 <= newC, newC < n else { continue }

                queue.insert(Heaper(r: newR, c: newC, dist: min(newGrid[newR][newC], cell.dist)))
            }

        }

        return 0
    }

}
