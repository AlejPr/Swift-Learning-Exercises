/*

 3751. Total Waviness of Numbers in Range I

 The waviness of a number is the count of its digits (excluding the first and last digit) that form
 a strict local peak or a strict local valley, i.e. a digit that is strictly greater than both of
 its neighbouring digits, or strictly smaller than both of them.

 Given two integers num1 and num2, return the sum of the waviness of every integer in the inclusive
 range [num1, num2].

 https://leetcode.com/problems/total-waviness-of-numbers-in-range-i/

 */

fileprivate class Solution {
    func totalWaviness(_ num1: Int, _ num2: Int) -> Int {
        guard num1 >= 101 || num2 >= 101 else { return 0 }

        var ans = 0
        for num in max(101, num1)...num2 {
            var next = num % 10
            var last = next
            var x = num / 10

            while x >= 10 {
                let cur = x % 10
                x /= 10
                next = x % 10

                if (last < cur && next < cur) || last > cur && next > cur {
                    ans += 1
                }

                last = cur
            }
        }
        return ans
    }
}
