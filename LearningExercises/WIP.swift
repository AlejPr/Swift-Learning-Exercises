/*
 
 1199. Minimum Time to Build Blocks
 
You are given a list of blocks, where blocks[i] = t means that the i-th block needs t units of time to be built. A block can only be built by exactly one worker.

A worker can either split into two workers (number of workers increases by one) or build a block then go home. Both decisions cost some time.

The time cost of spliting one worker into two workers is given as an integer split. Note that if two workers split at the same time, they split in parallel so the cost would be split.

Output the minimum time needed to build all blocks.

Initially, there is only one worker.

 Example 1:

 Input: blocks = [1], split = 1
 Output: 1
 Explanation: We use 1 worker to build 1 block in 1 time unit.
 Example 2:

 Input: blocks = [1,2], split = 5
 Output: 7
 Explanation: We split the worker into 2 workers in 5 time units then assign each of them to a block so the cost is 5 + max(1, 2) = 7.
 Example 3:

 Input: blocks = [1,2,3], split = 1
 Output: 4
 Explanation: Split 1 worker into 2, then assign the first worker to the last block and split the second worker into 2.
 Then, use the two unassigned workers to build the first two blocks.
 The cost is 1 + max(3, 1 + max(1, 2)) = 4.
  

 Constraints:

 1 <= blocks.length <= 1000
 1 <= blocks[i] <= 10^5
 1 <= split <= 100
 
*/


fileprivate class Solution5 {
    func minBuildTime(_ blocks: [Int], _ split: Int) -> Int {
        return 0
    }
}




/*
 
 
 4009. Minimum Possible Maximum Waiting Time
 Hard
 Hint
 You are given an integer array demand, where demand[i] is the amount of fuel required by the ith car.

 You are also given an integer array fuel of length 2. There are exactly two fuel dispensers, numbered 0 and 1, where fuel[j] is the initial amount of fuel available in dispenser j.

 Cars are allowed to start refueling in increasing index order. Car 0 becomes allowed at time 0, and for each i > 0, car i becomes allowed exactly when car i - 1 starts refueling.

 The refueling process follows these rules:

 Each dispenser can serve at most one car at a time.
 When a car becomes allowed, you must choose a dispenser with at least demand[i] fuel remaining. If both dispensers have enough fuel remaining, you may choose either of them, regardless of when they become free.
 The car waits until the chosen dispenser becomes free and starts refueling immediately. It cannot switch dispensers or intentionally wait after the chosen dispenser becomes free.
 When a car starts refueling, the remaining fuel in the chosen dispenser decreases by demand[i], and the dispenser remains occupied for demand[i] seconds.
 Once started, refueling cannot be interrupted.
 If neither dispenser has at least demand[i] fuel remaining when car i becomes allowed, the process terminates and no further cars can be served.
 The waiting time of a car is the time between when it becomes allowed to start refueling and when it actually starts.

 Return the minimum possible value of the maximum waiting time among all served cars over all assignments that maximize the number of served cars. If no car can be served, return -1.

  

 Example 1:

 Input: demand = [6,8,4,6,5], fuel = [16,13]

 Output: 6

 Explanation:

 The following assignment serves all five cars:

 Car    Becomes allowed at    Starts refueling at    Dispenser used    Remaining fuel before start
 (dispenser 0, dispenser 1)    Waiting time
 0    0    0    0    (16, 13)    0
 1    0    0    1    (10, 13)    0
 2    0    6    0    (10, 5)    6
 3    6    10    0    (6, 5)    4
 4    10    10    1    (0, 5)    0
 Thus, all five cars are served, and the maximum waiting time is 6.

 To serve all five cars, dispenser 0 must serve the cars with demands 6, 4, and 6, while dispenser 1 must serve the cars with demands 8 and 5. Therefore, car 2 must wait until time 6 for dispenser 0 to become free, so no assignment serving all five cars can have a maximum waiting time less than 6.

 Example 2:

 Input: demand = [10,15], fuel = [12,17]

 Output: 0

 Explanation:

 At time 0, Car 0 becomes allowed and starts refuelling using dispenser 0.
 Car 1 becomes allowed at time 0 (when Car 0 starts) and immediately starts refuelling using dispenser 1.
 Both cars start without waiting, so the maximum waiting time is 0.
 Example 3:

 Input: demand = [10,5], fuel = [8,8]

 Output: -1

 Explanation:

 At time 0, Car 0 becomes allowed. However, neither dispenser has enough fuel to serve it, so the process terminates immediately.
 No car is served, so the answer is -1.
  

 Constraints:

 1 <= demand.length <= 50
 1 <= demand[i] <= 20
 fuel.length == 2
 1 <= fuel[i] <= 50
 
 
 */


fileprivate class Solution4 {
    func minMaxWaitingTime(_ demand: [Int], _ fuel: [Int]) -> Int {
        return 0
    }
}











struct CoolCustomHeap<T> {
    
    internal var arr: [T]
    internal var sort: (T,T) -> Bool
    
    init(_ startingArr: [T]? = nil,_ sort: @escaping (T, T) -> Bool) {
        self.arr = [T]()
        self.sort = sort
        if let startingArr = startingArr {
            for i in startingArr { insert(i) }
        }
    }
    
    public var count: Int { arr.count }
    public var first: T? { arr.first }
    
    public mutating func insert(_ newVal: T) {
        arr.append(newVal)
        siftUp(count - 1)
    }
    
    internal func parent(_ i :Int) -> Int { (i - 1) / 2 }
    internal func left(_ i: Int) -> Int { (i * 2) + 1 }
    internal func right(_ i: Int) -> Int { (i * 2) + 2 }
    
    public mutating func popFirst() -> T? {
        if arr.count == 0 { return nil }
        if arr.count == 1 { return arr.removeFirst() }
        let first = arr[0]
        arr[0] = arr.removeLast()
        siftDown(0)
        return first
    }
    
    internal mutating func siftDown(_ i: Int) {
        var cur = i
        while true {
            let left = left(cur), right = right(cur)
            var cand = cur
            
            if left < count && !sort(arr[cand], arr[left]) { cand = left }
            if right < count && !sort(arr[cand], arr[right]) { cand = right }
            if cand == cur { return }
            
            arr.swapAt(cur, cand)
            cur = cand
        }
    }
    
    internal mutating func siftUp(_ i: Int) {
        var cur = i, par = parent(i)
        while cur > 0 {
            guard sort(arr[cur], arr[par]) else { return }
            arr.swapAt(cur, par)
            cur = par
            par = parent(cur)
        }
    }
    
}


/*
[1,2,3,4,5,6,7]
2
4 3
7 5 6
*/

//[2, 4, 3, 7, 5, 6]
