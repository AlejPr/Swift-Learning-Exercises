/*

 3753. Total Waviness of Numbers in Range II

 The waviness of a number is the count of its digits (excluding the first and last digit) that form
 a strict local peak or a strict local valley, i.e. a digit that is strictly greater than both of
 its neighbouring digits, or strictly smaller than both of them.

 Given two integers num1 and num2, return the sum of the waviness of every integer in the inclusive
 range [num1, num2]. The bounds are large, so the range is counted with digit DP rather than by
 iterating over every value.

 https://leetcode.com/problems/total-waviness-of-numbers-in-range-ii/

 */

fileprivate class Solution {
    func totalWaviness(_ num1: Int, _ num2: Int) -> Int {
        return solve(num2) - solve(num1 - 1)
    }

    //Builds the solution for every number from 0...N, one digit at a time
    //So builds like [1] -> [1, 0] -> [1, 0, 1]... etc and counts the waviness for the total amount of #s the prefix applies to.
    private func solve(_ N: Int) -> Int {
        let digits = String(N).map { Int(String($0))! }
        let n = digits.count

        var memo:[[[[(Int, Int)?]]]] =
        Array(repeating: Array(repeating: Array(repeating: Array(repeating: nil,
            count: 11), count: 11), count: 2), count: n)

        //Returns (waviness, count) where count is how many numbers this prefix applies to
        func dp(_ idx: Int,_ started: Bool,_ tight: Bool, _ last1: Int,_ last2: Int) -> (Int, Int) {
            guard idx < n else { return (0, 1) }

            if !tight, let cached = memo[idx][started ? 1 : 0][last1 + 1][last2 + 1] { return cached }

            //tight limits the upperbound of the numbers you're allowed to build
            //if true, then you cannot exceed N's digit at this index.
            //if N is 123, then the array [0, 1] would not be tight because even if inserting 9 at the last digit it would not exceed 123
            let limit = tight ? digits[idx] : 9
            var wTotal = 0
            var cTotal = 0
            for dig in 0...limit {
                let nextTight = tight && (dig == limit)

                if !started {
                    let (wMod, cMod) = {
                        if dig == 0 { return dp(idx + 1, false, nextTight, last1, last2) }
                        return dp(idx + 1, true, nextTight, last1, dig)
                    }()
                    wTotal += wMod; cTotal += cMod
                }

                else {
                    //Marks a peak / valley. if contrib is 1 then every number built from this prefix has +1 peak / valley.
                    var contrib = 0
                    if last1 != -1 && last2 != -1 {
                        if (last1 > last2 && dig > last2) || (last1 < last2 && dig < last2) { contrib = 1 }
                    }
                    let (wMod, cMod) = dp(idx + 1, true, nextTight, last2, dig)
                    wTotal += wMod + (contrib * cMod)
                    cTotal += cMod
                }

            }

            let res = (wTotal, cTotal)
            //Add +1 to last1/last2 to prevent out of bounds when they're equal to -1
            if !tight { memo[idx][started ? 1 : 0][last1 + 1][last2 + 1] = res }
            return res
        }

        return dp(0, false, true, -1, -1).0
    }

}



/*

assert( Solution().totalWaviness(2549294942, 5067104447) == 11661365485 )

*/
