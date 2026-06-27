fileprivate class Solution {
    
    //Create a dictionary counting the occurance of each number in the array, then iterate through each number and try to build the longest sequence possible.
    //EX. for number 2, keep iterating through powers until you can no longer find the next number in the dictionary... 2 / 4 / 16 / 256 = ans 9
    func maximumLength(_ nums: [Int]) -> Int {
        guard nums.count > 0 else { return 0 }
        let dict = nums.reduce(into: [Int: Int]()) { $0[$1, default : 0] += 1 }

        //Ones (and zeros, however that's not a valid input) need to be processed seperately as exponentiation would lead to infinite loops.
        let ones = dict[1] ?? 0
        var ans = max(1, ones & 1 == 1 ? ones : ones - 1)
        
        for num in dict where num.key != 1 && num.value >= 2 {
            var cur = num.key * num.key, count = 2
            
            while let next = dict[cur] {
                count += 2
                cur *= cur
                guard next >= 2 else { break }
            }
            
            count -= 1
            ans = max(ans, count)
        }
        
        return ans
    }
    
}
