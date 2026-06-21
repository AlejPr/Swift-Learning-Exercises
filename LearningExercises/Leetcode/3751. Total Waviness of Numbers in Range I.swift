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
