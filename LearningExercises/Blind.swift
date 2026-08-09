

import Foundation


struct CustomHeap2<T> {
    
    private(set) var arr = [T]()
    internal let sort: (T, T) -> Bool
    
    init(_ sort: @escaping (T,T) -> Bool) {
        self.sort = sort
    }
    
    public var count: Int { arr.count }
    public var first: T? { arr.first }
    
    public mutating func insert(_ val: T) {
        arr.append(val)
        siftUp(count - 1)
    }
    
    public mutating func popFirst() -> T? {
        guard count > 1 else { return arr.popLast() }
        let first = arr[0]
        arr[0] = arr.removeLast()
        siftDown(0)
        return first
    }
    
    //3
    //6, 2
    
    //
    //
    
    internal mutating func siftDown(_ i: Int) {
        defer { print("finished", arr) }
        var parent = i
        while true {
            let left = left(parent), right = right(parent)
            var candidate = parent
            
            if left < count && sort(arr[left], arr[candidate]) {
                print(arr)
                print(arr[left], arr[candidate])
                candidate = left
            }
            
            if right < count && sort(arr[right], arr[candidate]) {
                candidate = right
            }
            
            if candidate == parent { return }
            print("swap", arr[candidate], arr[parent])
            arr.swapAt(candidate, parent)
            parent = candidate
        }
    }
    
    private func parent(_ i: Int) -> Int { (i - 1) / 2 }
    private func left(_ i: Int) -> Int { (2 * i) + 1 }
    private func right(_ i: Int) -> Int { (2 * i) + 2 }

    internal mutating func siftUp(_ i: Int) {
        var cur = i, par = parent(cur)
        while cur > 0 && sort(arr[cur], arr[par]) {
            arr.swapAt(cur, par)
            cur = par; par = parent(par)
        }
    }
    
}
























struct CustomHeap3<T> {
    
    internal let sort: (T, T) -> Bool
    internal var heap: [T]
    
    init(_ sort: @escaping (T, T) -> Bool) {
        self.heap = [T]()
        self.sort = sort
    }
    
    public var count: Int { heap.count }
    public var isEmpty: Bool { heap.isEmpty }
    public var first: T? { heap.first }
    
    public mutating func insert(_ val: T) {
        heap.append(val)
        siftUp(count - 1)
    }
    
    public mutating func popFirst() -> T? {
        guard !heap.isEmpty else { return nil }
        guard heap.count > 1 else { return heap.removeFirst() }
        let first = heap[0]
        heap[0] = heap.removeLast()
        siftDown(0)
        return first
    }
    
    private func parent(_ i: Int) -> Int { (i - 1) / 2 }
    private func left(_ i: Int) -> Int { (i * 2) + 1 }
    private func right(_ i: Int) -> Int { (i * 2) + 2 }
    
    private mutating func siftUp(_ i: Int) {
        var cur = i, par = parent(i)
        while cur > 0, sort(heap[cur], heap[par]) {
            heap.swapAt(cur, par)
            cur = par; par = parent(par)
        }
    }
    
    private mutating func siftDown(_ i: Int) {
        var parent = i
        while true {
            let left = left(parent), right = right(parent)
            var candidate = parent
            
            if left < count && !sort(heap[candidate], heap[left]) {
                candidate = left
            }
            
            if right < count && !sort(heap[candidate], heap[right]) {
                candidate = right
            }
            
            if candidate == parent { return }
            heap.swapAt(parent, candidate)
            parent = candidate
        }
    }
    
    
}






















struct FlexSegTree<T> {
    
    internal let length: Int
    internal var tree: [T]
    internal let operation: (T, T) -> T
    
    init(_ length: Int,_ defValue: T, operation: @escaping (T, T) -> T) {
        self.length = length
        self.tree = Array(repeating: defValue, count: 2 * length)
        self.operation = operation
    }
    
    public mutating func update(_ i: Int,_ val: T) {
        var i = i + length; tree[i] = val
        i /= 2
        
        while i > 0 {
            tree[i] = operation(tree[i * 2], tree[(i * 2) + 1])
            i /= 2
        }
    }
    
    public mutating func query(_ left: Int,_ right: Int) -> T {
        var left = left + length, right = right + length + 1
        
        var ans = tree[0]
        while left < right {
            if (left % 2 == 1) {
                ans = operation(tree[left], ans)
                left += 1
            }
            if (right % 2 == 1) {
                right -= 1
                ans = operation(tree[right], ans)
            }
            left /= 2; right /= 2
        }
        
        return ans
    }
    
    
    //[0, 5, 3, 2, 3, 5]
    
}
