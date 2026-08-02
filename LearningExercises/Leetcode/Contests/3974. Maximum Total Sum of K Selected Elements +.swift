/*

 3974. Maximum Total Sum of K Selected Elements

 You are given an integer array nums and two integers k and mul.

 Select exactly k elements from nums. Process these elements one by one in any order you choose.

 For each selected element, independently choose one of the following:

 Add the element's value to the total sum, or
 Multiply the element by the current value of mul and add the result to the total sum.
 After processing each selected element, mul decreases by 1, regardless of which option was chosen. The current value of mul may become 0 or negative.

 Return an integer denoting the maximum possible total sum.

 https://leetcode.com/problems/maximum-total-sum-of-k-selected-elements/

 */

fileprivate func maxSum(_ nums: [Int], _ k: Int, _ mul: Int) -> Int {
    let sorted = nums.sorted(by: >)
    var ans = 0, mul = mul
    for i in 1...k {
        let num = sorted[i - 1]
        if (mul * num) > num { ans += (mul * num); mul -= 1 }
        else { ans += num }
    }

    return ans
}





/*

 //MARK: - 3975. Filter Occupied Intervals
 You are given a 2D integer array occupiedIntervals, where occupiedIntervals[i] = [starti, endi] represents a time interval during which you are occupied. Each interval starts at starti and ends at endi, inclusive. These intervals may overlap.

 You are also given two integers freeStart and freeEnd, which define a free time interval from freeStart to freeEnd, inclusive.

 Your task is to merge all occupied intervals that overlap or touch, then remove all integer points in the free interval from the merged occupied intervals.

 Two intervals touch if the second interval starts immediately after the first one ends. For example, [1, 1] and [2, 2] touch and should be merged into [1, 2].

 Return the remaining occupied intervals in sorted order. The returned intervals must be non-overlapping and must contain the minimum number of intervals possible. If there are no remaining occupied points, return an empty list.

*/


fileprivate func filterOccupiedIntervals(_ occupiedIntervals: [[Int]], _ freeStart: Int, _ freeEnd: Int) -> [[Int]] {
    let sorted = occupiedIntervals.sorted {
        if $0[0] == $1[0] { return $0[1] > $1[1] }
        return $0[0] < $1[0]
    }

    //merge the intervals
    var start = sorted.first![0], end = sorted.first![1]
    var merged = [[Int]]()
    for i in sorted {
        let iStart = i[0], iEnd = i[1]
        if iStart > end + 1 {
            merged.append([start, end])
            start = iStart; end = iEnd
            continue
        }
        else { end = max(end, iEnd) }

    }
    merged.append([start, end])

    var ans = [[Int]]()

    //subtract any intervals that are inside freestart, freeend, then modify any that interlap
    for i in merged {
        let iStart = i[0], iEnd = i[1]
        if iEnd < freeStart { ans.append(i); continue }
        if iStart > freeEnd { ans.append(i); continue }
        if iEnd < freeStart && iEnd < freeStart { continue }

        if iStart < freeStart && freeEnd < iEnd {
            var i1 = i, i2 = i
            i1[1] = freeStart - 1; i2[0] = freeEnd + 1
            ans.append(i1); ans.append(i2)
        }

        else {
            var newStart = iStart, newEnd = iEnd
            if newStart < freeStart && newEnd >= freeStart { newEnd = freeStart - 1 }
            else { newStart = freeEnd + 1 }
            guard newStart <= newEnd else { continue }
            ans.append([newStart, newEnd])
        }

    }

    return ans
}
