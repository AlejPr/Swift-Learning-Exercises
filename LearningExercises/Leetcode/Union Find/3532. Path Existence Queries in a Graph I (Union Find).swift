/*

 3532. Path Existence Queries in a Graph I

 You are given an integer n representing the number of nodes in a graph, labeled from 0 to n - 1.

 You are also given an integer array nums of length n sorted in non-decreasing order, and an integer maxDiff.

 An undirected edge exists between nodes i and j if the absolute difference between nums[i] and nums[j] is at most maxDiff (i.e., |nums[i] - nums[j]| <= maxDiff).

 You are also given a 2D integer array queries. For each queries[i] = [ui, vi], determine whether there exists a path between nodes ui and vi.

 Return a boolean array answer, where answer[i] is true if there exists a path between ui and vi in the ith query and false otherwise.

 https://leetcode.com/problems/path-existence-queries-in-a-graph-i/

 */

///Standard union find implementation (with a swift twist!)
///Since nums is in order, the question is only asking whether or not any single path from node i to j is bigger than maxDiff; if so the entire path is invalid
///Union find easily merges all nodes from i to j that are within these bounds.
fileprivate class Solution {
    func pathExistenceQueries(_ n: Int, _ nums: [Int], _ maxDiff: Int, _ queries: [[Int]]) -> [Bool] {
        var disjointSet = UnionFind(n)
        var ans = [Bool]()

        for i in 1..<nums.count {
            if abs(nums[i - 1] - nums[i]) <= maxDiff { disjointSet.union(i - 1, i) }
        }

        for query in queries {
            ans.append( disjointSet.find(query[0]) == disjointSet.find(query[1]) )
        }

        return ans
    }

    struct UnionFind {

        internal var parents: [Int]
        internal var rankings: [Int]

        init(_ size: Int) {
            parents = Array(0...size - 1)
            rankings = Array(repeating: 1, count: size)
        }

        public mutating func find(_ x: Int) -> Int {
            if parents[x] != x { parents[x] = find(parents[x]) }
            return parents[x]
        }

        @discardableResult
        public mutating func union(_ x: Int,_ y: Int) -> Bool {
            let xParent = find(x), yParent = find(y)
            if xParent == yParent { return false }

            if rankings[xParent] > rankings[yParent] {
                rankings[xParent] += rankings[yParent]
                parents[yParent] = xParent
            }
            else {
                rankings[yParent] += rankings[xParent]
                parents[xParent] = yParent
            }
            return true
        }

    }

}
