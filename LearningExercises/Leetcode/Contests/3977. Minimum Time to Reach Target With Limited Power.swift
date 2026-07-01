/*
 //MARK: - 3977. Minimum Time to Reach Target With Limited Power
 You are given a directed weighted graph with n nodes labeled from 0 to n - 1.

 The graph is represented by a 2D integer array edges, where edges[i] = [ui, vi, ti] indicates a directed edge from node ui to node vi that takes ti seconds to traverse.

 You are also given an integer power representing the initial available power, and an integer array cost of length n, where cost[u] represents the power required to forward the signal from node u through any one of its outgoing edges.

 You are given two integers source and target.

 The signal starts at source at time 0 with power units of power and follows these rules:

 The signal may traverse a directed edge from node u only if the remaining power is at least cost[u].
 No power is consumed when the signal arrives at a node, unless it later leaves that node by traversing another edge.
 When the signal is forwarded from node u, the remaining power is decreased by cost[u] units.
 Traversing an edge edges[i] = [ui, vi, ti] increases the total time by ti seconds.
 Return an integer array answer of size 2, where:

 answer[0] is the minimum time required for the signal to reach node target.
 answer[1] is the maximum remaining power among all paths that achieve answer[0].
 If the signal cannot reach target, return [-1, -1].
 
 */


import Collections

fileprivate class Solution {

    struct Heaper: Comparable {
        var node: Int
        var power: Int
        var time: Int
        
        //Sort prioritizes minimum time, then maximum power.
        public static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs.time == rhs.time { return lhs.power > rhs.power }
            return lhs.time < rhs.time
        }
    }
    
    ///Standard Djikstra's search over the graph. Since the heap sort is ordered by time, then power, it's always guaranteed to return the minimum time to reach the target as well as the highest power.
    ///EX. In the case of reaching node 4, where one path is (time: 2, power: 5), and the second path is (time: 2, power: 7), path 2 would be processed first.
    ///And of course, Djikstra's guarantees minimum time to reach a node. No DP needed.
    func minTimeMaxPower(_ n: Int, _ edges: [[Int]], _ power: Int, _ cost: [Int], _ source: Int, _ target: Int) -> [Int] {
        //Build the Graph
        var graph = [Int: [(dest: Int, time: Int)]]()
        for edge in edges { graph[edge[0], default: []].append((dest: edge[1], time: edge[2])) }

        var visited = Array(repeating: -1, count: n)
        var queue: Heap<Heaper> = [Heaper(node: source, power: power, time: 0)]
        
        while let next = queue.popMin() {
            //Visited array cuts off pathways that have lower power than another path that has already been traversed.
            if next.power <= visited[next.node] { continue }
            visited[next.node] = next.power

            //Found the target with minimum time and maximum power
            if next.node == target { return [next.time, next.power] }
            guard let children = graph[next.node] else { continue }
            
            //Continue searching across the graph
            for edge in children {
                let newPower = next.power - cost[next.node]
                guard newPower >= 0 else { continue }
                queue.insert(Heaper(node: edge.dest, power: newPower, time:next.time + edge.time))
            }
            
        }
        
        return [-1, -1]
    }
}
