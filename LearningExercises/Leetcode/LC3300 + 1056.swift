
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
