/*

 3161. Block Placement Queries

 Nightmare problem

 The problem is asking you to efficiently keep track of the largest intervals between 0 and X, update the available intervals, and query them. Since the input size goes up to 150,000 queries, a segment tree is needed for efficient updating and querying, as it supports both of these operations are O(logN) time.

 Iterate over all queries to find the maximum distance the X line extends.
 Create a standard segment tree with a length of length + 2 (final value is a sentinel for indexing safety)

 Leaves in the tree contain the maximum interval to the leftmost obstacle, so in a line with no obstacles and a max index of 4, the bottom of the tree would look like [0, 0, 0, 0, 0, 4, 1] (index 6 is the sentinel value at the end)

 To calculate the updated intervals every time an obstacle is placed, keep a sorted array of all obstacles and binary search for the correct insertion points as well as the previous and next obstacle for the query insert.

    - Note that X = 0 and X = length + 1 are effectively obstacles; they mark the beginning and end of the line.
    - EX. obstacles = [0, 2,6,7,9,11,17] - placing 13, left = 11, right = 17
    - New value at the treenode for 17 would be 4, value at 13 would be 2, 11 does not need to be updated.

 Finally query the tree to calculate if it contains an interval of size sz or greater from 0 to X. Note that since intervals are stored in the rightmost node of the tree, it's possible to query to the left and retrieve an interval of 0 when there are few obstacles. To fix this, manually calculate the interval to the leftmost obstacle from the query X using binary search once more, then compare the largest interval - that to the leftmost object, or the query result.

    - EX. obstacles = [0, 17] - but the query is from 0 to 9. The tree would return 0, but the interval available here is 9. So you would compare sz to max(9 - 0, query(0, 9))

 https://leetcode.com/problems/block-placement-queries/

 */


fileprivate class Solution {

    func getResults(_ queries: [[Int]]) -> [Bool] {

        //Calculate the max length of the number line
        var length = 0
        for query in queries { length = max(query[1], length) }

        let st = SegmentTree(length + 2) //Initialize the segment tree with extra space
        var obstacles: [Int] = [0, length + 1] //Add the bounds of the line as obstacles
        st.update(length + 1, length + 1) //Update the tree for the bounds to give it an interval of size length + 1

        var ans = [Bool]()
        for query in queries {

            if query[0] == 1 {
                placeObstacle(at: query[1], &obstacles, st)
            }

            //Block query
            else {
                let x = query[1], sz = query[2]
                let prev = floor(x, obstacles)
                let intervalFromLastObstacleToCurX = x - prev
                let availableSpace = max(intervalFromLastObstacleToCurX, st.query(0, x))
                ans.append(availableSpace >= sz)
            }
        }

        return ans
    }

    //Find the obstacles to the left and right of the new obstacle, then recalculate the intervals.
    //Note that each leaf in the segTree contains the size of the interval to the obstacle LEFT of the node - so for the obstacles [11, 17], the node 17 contains the interval 6.
    private func placeObstacle(at index: Int,_ obstacles: inout [Int], _ st: SegmentTree) {
        let left = floor(index - 1, obstacles), right = ceiling(index + 1, obstacles)
        obstacles.insert(index, at: insertionIndex(index, obstacles))

        st.update(index, index - left)
        st.update(right, right - index)
    }

    //Finds the value closest to the target value but still smaller
    private func floor(_ target: Int, _ arr: [Int]) -> Int {
        var lo = 0, hi = arr.count - 1, ans = arr[0]
        while lo <= hi {
            let mid = (lo + hi) / 2
            if arr[mid] <= target { ans = arr[mid]; lo = mid + 1 }
            else { hi = mid - 1 }
        }
        return ans
    }

    //Finds the value closest to the target value but still bigger
    private func ceiling(_ target: Int, _ arr: [Int]) -> Int {
        var lo = 0, hi = arr.count - 1, ans = arr[arr.count - 1]
        while lo <= hi {
            let mid = (lo + hi) / 2
            if arr[mid] >= target { ans = arr[mid]; hi = mid - 1 }
            else { lo = mid + 1 }
        }
        return ans
    }

    private func insertionIndex(_ target: Int, _ arr: [Int]) -> Int {
        var lo = 0, hi = arr.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if arr[mid] < target { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

}


//Standard Flat iterative segment tree implementation (Check LC307 (Segment Tree).swift for comments explaining the tree)
final class SegmentTree {

    var tree: [Int]
    let length: Int

    init(_ length: Int) { self.length = length; tree = Array(repeating: 0, count: length * 2 ) }

    func update(_ index: Int,_ val: Int) {
        var index = index + length
        tree[index] = val

        while index > 1 {
            index >>= 1
            tree[index] = max(tree[index * 2], tree[index * 2 + 1])
        }
    }

    func query(_ left: Int,_ right: Int) -> Int {
        var left = left + length, right = right + length + 1

        var ans = 0
        while left < right {
            if (left & 1) == 1 { ans = max(ans, tree[left]); left += 1 }
            if (right & 1) == 1 { right -= 1; ans = max(ans, tree[right]) }
            left /= 2; right /= 2
        }

        return ans
    }

}

