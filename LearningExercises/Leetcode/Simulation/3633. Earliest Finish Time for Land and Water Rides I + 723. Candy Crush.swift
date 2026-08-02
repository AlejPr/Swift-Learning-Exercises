/*

 3633. Earliest Finish Time for Land and Water Rides I

 You are given two categories of theme-park rides: land rides and water rides. For the i-th land
 ride you are given a start time landStartTime[i] and duration landDuration[i]; water rides are
 given similarly. A tourist must experience exactly one ride from each category, in either order,
 but a ride can only begin once the previous ride (if any) has finished. Return the earliest
 possible time at which the tourist can finish experiencing both a land ride and a water ride.

 https://leetcode.com/problems/earliest-finish-time-for-land-and-water-rides-i/


 723. Candy Crush

 This question is about implementing a basic elimination algorithm for Candy Crush. Given a 2D
 integer array board representing the grid of candy where board[i][j] represents the type of candy,
 a value of board[i][j] == 0 represents an empty cell. Crush the board until it is stable: if three
 or more candies of the same type are adjacent vertically or horizontally, crush them all at the
 same time; after crushing, remaining candies drop to fill empty space. Return the stable board.

 https://leetcode.com/problems/candy-crush/

 */

fileprivate class Solution1 {
    func earliestFinishTime(_ landStartTime: [Int], _ landDuration: [Int], _ waterStartTime: [Int], _ waterDuration: [Int]) -> Int {
        return min(
            solve(landStartTime, landDuration, waterStartTime, waterDuration),
            solve(waterStartTime, waterDuration, landStartTime, landDuration)
        )
    }

    private func solve (_ st1: [Int],_ d1: [Int],_ st2: [Int],_ d2: [Int]) -> Int {
        var fin1 = Int.max
        for i in st1.indices {
            fin1 = min(fin1, st1[i] + d1[i])
        }

        var fin2 = Int.max
        for i in st2.indices {
            fin2 = min(fin2, max(st2[i], fin1) + d2[i])
        }
        return fin2
    }
}


fileprivate class CandyCrushSolution {
    func candyCrush(_ board: [[Int]]) -> [[Int]] {
        var board = board
        while crush(&board) { settle(&board) }
        return board
    }

    private func crush(_ board: inout [[Int]]) -> Bool {
        var tocrush = Array(repeating: Array(repeating: false, count: board[0].count), count: board.count)

        for r in board.indices {
            for c in board[0].indices where board[r][c] != 0 {
                let val = board[r][c]

                // Check horizontal
                var hCount = 1
                var newC = c + 1
                while newC < board[0].count && board[r][newC] == val { hCount += 1; newC += 1 }
                if hCount >= 3 {
                    for i in c..<c+hCount { tocrush[r][i] = true }
                }

                // Check vertical
                var vCount = 1
                var newR = r + 1
                while newR < board.count && board[newR][c] == val { vCount += 1; newR += 1 }
                if vCount >= 3 {
                    for i in r..<r+vCount { tocrush[i][c] = true }
                }
            }
        }

        var modified = false
        for r in board.indices {
            for c in board[0].indices where tocrush[r][c] {
                board[r][c] = 0
                modified = true
            }
        }
        return modified
    }

    private func settle(_ board: inout [[Int]]) {
        for c in 0..<board[0].count {
            var writeR = board.count - 1
            for r in stride(from: board.count - 1, through: 0, by: -1) {
                if board[r][c] != 0 {
                    board[writeR][c] = board[r][c]
                    writeR -= 1
                }
            }
            while writeR >= 0 {
                board[writeR][c] = 0
                writeR -= 1
            }
        }
    }

}
