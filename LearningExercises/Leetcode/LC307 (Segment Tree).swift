
//fileprivate typealias SegTree = ObjectSegTree
fileprivate final class ObjectSegTree {
    var leftBound: Int, rightBound: Int
    var left: ObjectSegTree!
    var right: ObjectSegTree!
    var sum: Int

    convenience init(_ arr: [Int]) { self.init(0, arr.count - 1, arr) }
    
    private init(_ leftBound: Int,_ rightBound: Int,_ arr: [Int]) {
        self.leftBound = leftBound; self.rightBound = rightBound
        if leftBound == rightBound { sum = arr[leftBound]; return }

        //split the range in two and create two child nodes
        let mid = (leftBound + rightBound) / 2
        self.left = ObjectSegTree(leftBound, mid, arr)
        self.right = ObjectSegTree(mid + 1, rightBound, arr)

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


fileprivate typealias SegTree = FlatSegTree
struct FlatSegTree {
    var tree: [Int]
    let length: Int

    init(_ arr: [Int]) {
        self.tree = Array(repeating: 0, count: 4 * arr.count)
        self.length = arr.count
        build(1, 0, arr.count - 1, arr)
    }

    private mutating func build(_ node: Int,_ left: Int,_ right: Int,_ arr: [Int]) {
        if left == right { tree[node] = arr[left] }
        else {
            let mid = (left + right) / 2
            build (2 * node, left, mid, arr)
            build (2 * node + 1, mid + 1, right, arr)

            tree[node] = tree[2 * node] + tree[2 * node + 1]
        }
    }
    
    //Public Interface for easy queries / updates
    mutating func update(_ index: Int,_ val: Int) { update(1, 0, length - 1, index, val)}
    func query(_ queryLeft: Int,_ queryRight: Int) -> Int { return query(1, 0, length - 1, queryLeft, queryRight) }


    @_optimize(speed)
    private mutating func update(_ node: Int,_ left: Int,_ right: Int,_ index: Int,_ val: Int) {
        //Leaf node, update the value
        if left == right { tree[node] = val; return }
        
        //Branch node, recursively update the values of further branches / leaves
        let mid = (left + right) / 2

        if left <= index && index <= mid {
            //Index to update is on the left path
            update(2 * node, left, mid, index, val)
        } else {
            //Index to update is on the right path
            update(2 * node + 1, mid + 1, right, index, val)
        }

        tree[node] = tree[2 * node] + tree[2 * node + 1]
    }


    @_optimize(speed)
    private func query(_ node: Int,_ left: Int,_ right: Int,_ queryLeft: Int,_ queryRight: Int) -> Int {
        //Range is disjoint
        if left > queryRight || right < queryLeft { return 0 }
        
        //Range is included in node
        if queryLeft <= left && right <= queryRight { return tree[node] }

        //Unknown, search deeper in tree
        let mid = (left + right) / 2
        return query(2 * node, left, mid, queryLeft, queryRight) + query(2 * node + 1, mid + 1, right, queryLeft, queryRight)
    }

}


class NumArray {

    fileprivate var st: SegTree

    init(_ nums: [Int]) { st = SegTree(nums) }
    
    func update(_ index: Int, _ val: Int) { st.update(index, val) }
    
    func sumRange(_ left: Int, _ right: Int) -> Int { return st.query(left, right) }

}
