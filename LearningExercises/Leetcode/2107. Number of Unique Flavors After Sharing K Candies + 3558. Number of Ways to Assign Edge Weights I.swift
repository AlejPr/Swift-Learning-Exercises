fileprivate class Solution {
    func assignEdgeWeights(_ edges: [[Int]]) -> Int {
        let mod = 1_000_000_000 + 7
        
        var graph = [Int: [Int]]()
        var reverse = [Int: [Int]]()

        for edge in edges {
            graph[edge[0], default: []].append(edge[1])
            reverse[edge[1], default: []].append(edge[0])
        }

        let depth = max(maxDepth(1, graph), maxDepth(1, reverse))
        var ans = 1
        for i in stride(from: 2, to: depth, by: 1) {
            ans = (ans * 2) % mod
        }

        return ans
    }


    private func maxDepth(_ node: Int,_ graph: [Int: [Int]]) -> Int {
        guard let children = graph[node] else { return 1 }
        var ans = 1
        for child in children {
            ans = max(ans, maxDepth(child, graph) + 1)
        }
        return ans
    }
}


fileprivate class Solution2 {
    func shareCandies(_ candies: [Int], _ k: Int) -> Int {
        var inDegree = candies.reduce(into: [Int: Int]()) { $0[$1, default: 0] += 1 }

        func decrement(_ x: Int) {
            inDegree[x]? -= 1
            if inDegree[x] == 0 { inDegree.removeValue(forKey: x) }
        }

        for i in 0..<k { decrement(candies[i]) }

        var ans = inDegree.count, lhs = 0, rhs = max(0, k)
        while rhs < candies.count {
            inDegree[candies[lhs], default: 0] += 1
            decrement(candies[rhs])
            lhs += 1; rhs += 1
            ans = max(ans, inDegree.count)
        }

        return ans
    }
}
