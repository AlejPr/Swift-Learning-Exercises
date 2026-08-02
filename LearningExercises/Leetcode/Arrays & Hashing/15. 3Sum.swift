/*

 15. 3Sum

 Given an integer array nums, return all the triplets [nums[i], nums[j], nums[k]] such that
 i != j, i != k, and j != k, and nums[i] + nums[j] + nums[k] == 0.

 The solution set must not contain duplicate triplets.

 Input: nums = [-1,0,1,2,-1,-4]
 Output: [[-1,-1,2],[-1,0,1]]

 https://leetcode.com/problems/3sum/

 */

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
