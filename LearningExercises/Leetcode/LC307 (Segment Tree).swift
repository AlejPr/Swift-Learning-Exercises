
fileprivate typealias SegTree = ObjectSegTree
fileprivate final class ObjectSegTree {
    var leftBound: Int, rightBound: Int
    var left: SegTree!
    var right: SegTree!
    var sum: Int

    init(_ leftBound: Int,_ rightBound: Int,_ arr: [Int]) {
        self.leftBound = leftBound; self.rightBound = rightBound
        if leftBound == rightBound { sum = arr[leftBound]; return }

        //split the range in two and create two child nodes
        let mid = (leftBound + rightBound) / 2
        self.left = SegTree(leftBound, mid, arr)
        self.right = SegTree(mid + 1, rightBound, arr)

        self.sum = left.sum + right.sum
    }

    @_optimize(speed)
    public func update(_ index: Int,_ val: Int) {
        //leaf node, cannot go further down
        if leftBound == rightBound { sum = val; return }

        //Branch node
        let l = left!, r = right!
        if index <= l.rightBound { l.update(index, val) }
        else { r.update(index, val) }

        sum = l.sum + r.sum
    }

    @_optimize(speed)
    public func query(_ l: Int,_ r: Int) -> Int {
        //out of bounds
        if (l > rightBound || r < leftBound) { return 0 }

        //range entirely covers this node of the tree - [0, 5] but our node is in [1, 3]
        if (l <= leftBound && r >= rightBound) { return self.sum }

        //requires searching further inside the tree
        let mid = (leftBound + rightBound) / 2
        if r <= mid { return left.query(l, r) }
        if l > mid  { return right.query(l, r) }
        return left.query(l, r) + right.query(l, r)
    }

}

class NumArray {

    fileprivate var st: SegTree

    init(_ nums: [Int]) { st = SegTree(0, nums.count - 1, nums) }
    
    func update(_ index: Int, _ val: Int) { st.update(index, val) }
    
    func sumRange(_ left: Int, _ right: Int) -> Int { return st.query(left, right) }

}


/*
struct FlatSegTree {
    var tree: [Int]

    init(_ arr: [Int]) {
        let arr =  [2, 9, 4, 5, 1, 3]
        self.tree = Array(repeating: 0, count: 3 * arr.count)

        func build(_ node: Int,_ left: Int,_ right: Int) {
            if left == right { tree[node] = arr[left] }
            else {
                let mid = (left + right) / 2
                build (2 * node, left, mid)
                build (2 * node + 1, mid + 1, right)

                tree[node] = tree[2 * node] + tree[2 * node + 1]
            }
        }

        build(1, 0, arr.count - 1)
    }
}
*/
