fileprivate class Solution {
    func threeSum(_ nums: [Int]) -> [[Int]] {
        var ans = Set<[Int]>()
        let nums = nums.sorted()
        //print(nums)

        for lhs in 0...nums.count - 2 {
            guard lhs == 0 || nums[lhs] != nums[lhs - 1] else { continue }
            
            var mid = lhs + 1, rhs = nums.count - 1
            while mid < rhs {
                //print(lhs, mid, rhs)
                let sum = nums[lhs] + nums[rhs]

                if nums[mid] == -sum {
                    ans.insert([nums[lhs], nums[mid], nums[rhs]])
                    rhs -= 1
                    mid += 1
                }
                else if nums[mid] < -sum { mid += 1 }
                else { rhs -= 1 }
            }

        }

        return Array(ans)
    }
}
