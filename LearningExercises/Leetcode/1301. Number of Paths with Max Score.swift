
/*
 
 1301. Number of Paths with Max Score
 
 You are given a square board of characters. You can move on the board starting at the bottom right square marked with the character 'S'.

 You need to reach the top left square marked with the character 'E'. The rest of the squares are labeled either with a numeric character 1, 2, ..., 9 or with an obstacle 'X'. In one move you can go up, left or up-left (diagonally) only if there is no obstacle there.

 Return a list of two integers: the first integer is the maximum sum of numeric characters you can collect, and the second is the number of such paths that you can take to get that maximum sum, taken modulo 10^9 + 7.

 In case there is no path, return [0, 0].
 
 */


///Robot paths like- Bottom up DP
///Calculate how many paths you can take to reach each cell by adding up the paths from the bottom, right, and bottom-right cells.
///The trick here is to first calculate the maximum score you can gather to reach a certain cell, and only add in the paths that reach that score.
fileprivate func pathsWithMaxScore(_ board: [String]) -> [Int] {
    let mod = 1_000_000_000 + 7
    let n = board.count
    var board = board.map { $0.map { $0 }}

    var dp = Array(repeating: Array(repeating: (0, 0), count: n), count: n)
    dp[n - 1][n - 1] = (0, 1)

    //fill far right col
    for r in stride(from: n - 2, through: 0, by: -1) {
        if board[r][n - 1] == "X" || dp[r + 1][n - 1].1 == 0 { continue }
        dp[r][n - 1].1 = 1; dp[r][n - 1].0 = dp[r + 1][n - 1].0 + board[r][n - 1].hexDigitValue!
    }

    //fill bottom row
    for c in stride(from: n - 2, through: 0, by: -1) {
        if board[n - 1][c] == "X" || dp[n - 1][c + 1].1 == 0 { continue }
        dp[n - 1][c].1 = 1; dp[n - 1][c].0 = dp[n - 1][c + 1].0 + board[n - 1][c].hexDigitValue!
    }

    
    //fill in remaining cells by checking the maximum score you can get to reach this cell, and the amount of paths that can reach said maximum score.
    for r in stride(from: n - 2, through: 0, by: -1) {
        for c in stride(from: n - 2, through: 0, by: -1) {
            guard board[r][c] != "X" else { continue }
            let adj = (r == 0 && c == 0) ? 0 : board[r][c].hexDigitValue!
            let right = dp[r][c + 1]
            let bottom = dp[r + 1][c]
            let diag = dp[r + 1][c + 1]

            guard right.1 != 0 || bottom.1 != 0 || diag.1 != 0 else { continue }
            let maxScore = max(
                right.0 + adj,
                bottom.0 + adj,
                diag.0 + adj
            )

            var totalPaths = 0
            for (score, paths) in [right, bottom, diag] where score + adj == maxScore {
                totalPaths = (totalPaths + paths) % mod
            }

            dp[r][c] = (maxScore, totalPaths)
        }
    }

    return [dp[0][0].0, dp[0][0].1]
}
