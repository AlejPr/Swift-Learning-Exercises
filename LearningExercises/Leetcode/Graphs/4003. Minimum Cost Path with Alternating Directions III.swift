/*

 4003. Minimum Cost Path with Alternating Directions III

 You are given two integers m and n representing the number of rows and columns of a grid. Your goal is to reach cell (m - 1, n - 1). You are also given a 2D integer array penalty.

 The cost to enter cell (i, j) is (i + 1) * (j + 1).

 You begin at cell (0, 0) and initially pay its entrance cost. Actions performed after entering (0, 0) are numbered starting from 1.

 On each action, you may move to an adjacent cell or wait in the current cell. A move follows the parity rule if:

 On an odd-numbered action, you move right or down.
 On an even-numbered action, you move left or up.
 The cost of an action is determined as follows:

 If you move according to the parity rule, pay only the entrance cost of the destination cell.
 If you move in a direction that violates the parity rule, pay the entrance cost of the destination cell plus penalty[i][j], where (i, j) is the cell you move from.
 If you wait in cell (i, j), pay penalty[i][j].
 After every move or wait, the action number increases by 1. Therefore, the required parity alternates after every action, regardless of whether a penalty was paid.

 Return the minimum total cost required to reach (m - 1, n - 1).

 Input: m = 2, n = 2, penalty = [[5,3],[1,4]]

 Output: 8

 https://leetcode.com/problems/minimum-cost-path-with-alternating-directions-iii/

 */

import Collections

fileprivate class Solution {
    func minCost(_ m: Int, _ n: Int, _ penalty: [[Int]]) -> Int {

        struct Heaper: Comparable {
            var i: Int
            var j: Int
            var act: Int
            var cost: Int
            public static func < (lhs: Heaper, rhs: Heaper) -> Bool { lhs.cost < rhs.cost }
            init(_ i: Int,_ j: Int,_ act: Int,_ cost: Int) { self.i = i; self.j = j; self.act = act; self.cost = cost }
        }

        //3d visited matrix, [row][col][parity], stores the minrmum cost to reach that state. parity is calculated either 0 or 1, depending on whether the move is even or odd
        var visited = Array(repeating: Array(repeating: Array(repeating: Int.max, count: 2), count: n), count: m)
        var queue: Heap<Heaper> = [Heaper(0, 0, 0, 1)]
        let dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)] //up, down, left, right

        while let q = queue.popMin() {
            if q.i == m - 1 && q.j == n - 1 { return q.cost }
            guard visited[q.i][q.j][q.act % 2] > q.cost else { continue }
            visited[q.i][q.j][q.act % 2] = q.cost
            var na = q.act + 1

            //wait in cell, pay penalty
            let newC = q.cost + penalty[q.i][q.j]
            if visited[q.i][q.j][na % 2] > newC {
                queue.insert(Heaper(q.i, q.j, na, newC))
            }

            for dir in dirs {
                let nr = q.i + dir.0, nc = q.j + dir.1
                guard nr >= 0, nr < m, nc >= 0, nc < n else { continue }
                let entryCost = (nr + 1) * (nc + 1)
                let even = q.act % 2 == 0

                var pen = 0
                //penalty for moving right or down on an odd turn
                if (dir.1 == 1 || dir.0 == 1) && !even {
                    pen = penalty[q.i][q.j]
                }

                //penalty for moving left or up on an even turn
                else if (dir.0 == -1 || dir.1 == -1) && even {
                    pen = penalty[q.i][q.j]
                }

                let cost = q.cost + entryCost + pen
                guard visited[nr][nc][na % 2] > cost else { continue }
                queue.insert(Heaper(nr, nc, na, cost))
            }
        }

        return -1 //unreachable
    }
}
