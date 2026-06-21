//https://leetcode.com/problems/create-binary-tree-from-descriptions/description/


//Definition for a binary tree node.
fileprivate class TreeNode {
    public var val: Int
    public var left: TreeNode?
    public var right: TreeNode?
    public init() { self.val = 0; self.left = nil; self.right = nil; }
    public init(_ val: Int) { self.val = val; self.left = nil; self.right = nil; }
    public init(_ val: Int, _ left: TreeNode?, _ right: TreeNode?) {
        self.val = val
        self.left = left
        self.right = right
    }
}

fileprivate class Solution {
    
    @_optimize(speed)
    func createBinaryTree(_ descriptions: [[Int]]) -> TreeNode? {
        guard descriptions.count > 0 else { return nil }
        
        var graph = [Int: [Int?]]()
        var reverse = [Int: Int]()
        
        for node in descriptions {
            graph[node[0], default: [nil, nil]][node[2] == 1 ? 0 : 1] = node[1]
            reverse[node[1]] = node[0]
        }
        
        //Search upwards for the root
        var root = reverse.first!.key
        while let next = reverse[root] { root = next }
        
        return build(root, graph)
    }
    
    @_optimize(speed)
    private func build(_ val: Int,_ graph: [Int: [Int?]]) -> TreeNode? {
        let node = TreeNode(val)
        guard let children = graph[val] else { return node }
        
        if let left = children[0] { node.left = build(left, graph) }
        if let right = children[1] { node.right = build(right, graph) }
        return node
    }

}
