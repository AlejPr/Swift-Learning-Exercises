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
