import Collections
/*
 
 2492. Minimum Score of a Path Between Two Cities
 
 You are given a positive integer n representing n cities numbered from 1 to n. You are also given a 2D array roads where roads[i] = [ai, bi, distancei] indicates that there is a bidirectional road between cities ai and bi with a distance equal to distancei. The cities graph is not necessarily connected.

 The score of a path between two cities is defined as the minimum distance of a road in this path.

 Return the minimum possible score of a path between cities 1 and n.

 Note:

 A path is a sequence of roads between two cities.
 It is allowed for a path to contain the same road multiple times, and you can visit cities 1 and n multiple times along the path.
 The test cases are generated such that there is at least one path between 1 and n.

 
 */


fileprivate class Solution {
    
    ///Standard BFS search with a deque, convert the edges into a graph + reversed graph
    func minScore(_ n: Int, _ roads: [[Int]]) -> Int {
        var graph = roads.reduce(into: [Int: [(node: Int, dist: Int)]]()) {
            $0[$1[0], default: []].append( (node: $1[1], dist: $1[2]) )
            $0[$1[1], default: []].append( (node: $1[0], dist: $1[2]) )
        }
        
        var visited = Array(repeating: 10_000_000, count: n + 1)
        var queue: Deque<(node: Int, minDist: Int)> = [(node: 1, minDist: 9_000_000)]

        while let first = queue.popFirst() {
            //marks a node as visited and records the best answer. If the current answer attached to the node is not better, discard the search path.
            if visited[first.node] <= first.minDist { continue }
            visited[first.node] = first.minDist

            guard let children = graph[first.node] else { continue }
            for child in children {
                let newMin = min(first.minDist, child.dist)
                guard visited[child.node] >= newMin else { continue }
                let newNode = (node: child.node, newMin)

                if newMin <= queue.first?.minDist ?? 10_000_000 { queue.prepend(newNode) }
                else { queue.append(newNode) }
            }
        }

        return visited[n]
    }
}
