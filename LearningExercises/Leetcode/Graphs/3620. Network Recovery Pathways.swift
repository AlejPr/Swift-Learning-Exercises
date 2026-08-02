/*

 3620. Network Recovery Pathways

 You are given a directed acyclic graph of n nodes numbered from 0 to n − 1. This is represented by a 2D array edges of length m, where edges[i] = [ui, vi, costi] indicates a one‑way communication from node ui to node vi with a recovery cost of costi.

 Some nodes may be offline. You are given a boolean array online where online[i] = true means node i is online. Nodes 0 and n − 1 are always online.

 A path from 0 to n − 1 is valid if:

 All intermediate nodes on the path are online.
 The total recovery cost of all edges on the path does not exceed k.
 For each valid path, define its score as the minimum edge‑cost along that path.

 Return the maximum path score (i.e., the largest minimum-edge cost) among all valid paths. If no valid path exists, return -1.

 https://leetcode.com/problems/network-recovery-pathways/

 */

import Collections

fileprivate class Solution {

    struct Heaper: Comparable {
        let node: Int
        let cost: Int
        static public func < (lhs: Heaper, rhs: Heaper) -> Bool {
            return lhs.cost < rhs.cost
        }
    }


    ///Tricky question, standard dijkstra does not work because of 2nd state constraint.
    ///Instead, we build a graph (ignoring offline nodes, they do not contribute to the solution in any way) and binary search over possible edge values.
    ///For each edge value, we check if it's possible to reach the end of the graph and either search left / right accordingly to reach the maximum answer.
    ///Regular dijkstras does not work because it's possible to visit a node with multiple competing states; the highest path score for a certain node may have a high cost that would render the path unfeasible, yet still block feasible paths with a lower score or lower cost from reaching the end of the graph.
    func findMaxPathScore(_ edges: [[Int]], _ online: [Bool], _ k: Int) -> Int {
        let n = online.count
        var values: Set<Int> = []


        var graph = edges.reduce(into: [Int: [(node: Int, cost: Int)]]()) {
            guard online[$1[1]] else { return }
            $0[$1[0], default: []].append((node:$1[1], cost: $1[2]))
            values.insert($1[2])
        }

        guard dijkstra(with: 0) else { return -1 }

        //Standard binary search
        let sorted = Array(values).sorted()
        var lhs = 0, rhs = sorted.count - 1, ans = 0
        while lhs <= rhs {
            let mid = (lhs + rhs) / 2
            if dijkstra(with: sorted[mid]) {
                ans = sorted[mid]
                lhs = mid + 1
            }
            else { rhs = mid - 1}
        }

        return ans

        //Only checks to make sure that a path is valid with the minimum score, and that it's possible to reach the end of the graph with that score.
        func dijkstra(with minScore: Int) -> Bool {
            var visited = Array(repeating: Int.max / 2, count: n)
            var queue: Heap<Heaper> = [Heaper(node: 0, cost: 0)]

            while let cur = queue.popMin() {
                if cur.node == n - 1 { return true }
                guard cur.cost < visited[cur.node] else { continue }
                visited[cur.node] = cur.cost

                guard let children = graph[cur.node] else { continue }
                for child in children where child.cost >= minScore {
                    let newCost = cur.cost + child.cost
                    guard newCost <= k else { continue }
                    queue.insert(Heaper(node: child.node, cost: newCost))
                }
            }

            return false
        }
    }

}
