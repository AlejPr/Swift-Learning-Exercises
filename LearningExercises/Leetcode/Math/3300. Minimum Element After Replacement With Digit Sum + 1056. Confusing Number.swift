/*

 3300. Minimum Element After Replacement With Digit Sum

 You are given an integer array nums. You replace each element in nums with the sum of its digits.
 Return the minimum element in nums after all replacements.

 https://leetcode.com/problems/minimum-element-after-replacement-with-digit-sum/


 1056. Confusing Number

 A confusing number is a number that when rotated 180 degrees becomes a different number, with each
 digit valid. We can rotate digits of a number by 180 degrees to form new digits.
   When 0, 1, 6, 8, and 9 are rotated 180 degrees, they become 0, 1, 9, 8, and 6 respectively.
   When 2, 3, 4, 5, and 7 are rotated 180 degrees, they become invalid.

 Given an integer n, return true if it is a confusing number, or false otherwise.

 https://leetcode.com/problems/confusing-number/

 */

fileprivate class Solution {

    func minElement(_ nums: [Int]) -> Int {
        var ans = Int.max
        for num in nums {
            var res = 0, n = num
            while n > 0 {
                res += n % 10
                n /= 10
            }
            ans = min(ans, res)
        }
        return ans
    }

    func confusingNumber(_ n: Int) -> Bool {
        let digits: [Character] = ["0", "1", "$", "$", "$", "$", "9", "$", "8", "6"]
        let n = String(n)
        var ans = [Character]()
        for char in n.reversed() {
            let newdigit = digits[char.hexDigitValue!]
            guard newdigit != "$" else {return false }
            ans.append(newdigit)
        }

        return String(ans) != n
    }

}
