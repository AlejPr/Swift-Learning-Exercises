//
//
//

///Custom Priority Queue (Heap) Implementation that provides support for a custom sort algorithm and changing an item's value with an index
struct PriorityQueue<T> {
    
    private(set) var heap = [T]()
    private let sort: (_ lhs: T, _ rhs: T) -> Bool
    
    init(sort: @escaping(_ lhs: T, _ rhs: T) -> Bool) {
        self.sort = sort
    }
    
    var isEmpty: Bool { heap.isEmpty }
    var count: Int { heap.count }
    
    public mutating func insert(_ element: T) {
        heap.append(element)
        siftUp(count - 1)
    }
    
    public func checkFirst() -> T? { heap.first }
    
    public mutating func popFirst() -> T? {
        guard !isEmpty else { return nil }
        if count == 1 { return heap.removeFirst() }
        let first = heap[0]
        heap[0] = heap.removeLast()
        siftDown(0)
        return first
    }
    
    private func parent(_ i: Int) -> Int { (i - 1) / 2 }
    private func left(_ i: Int) -> Int { (2 * i) + 1 }
    private func right(_ i: Int) -> Int { (2 * i) + 2 }
    
    private mutating func siftUp(_ i: Int) {
        var ch = i, pr = parent(i)
        while ch > 0 && sort(heap[ch], heap[pr]) {
            heap.swapAt(ch, pr)
            ch = pr; pr = parent(ch)
        }
    }
    
    private mutating func siftDown(_ i: Int) {
        var parent = i
        while true {
            let leftChild = left(parent), rightChild = right(parent)
            var candidate = parent
            
            if leftChild < count && sort(heap[leftChild], heap[candidate]) {
                candidate = leftChild
            }
            
            if rightChild < count && sort(heap[rightChild], heap[candidate]) {
                candidate = rightChild
            }
            
            if candidate == parent { return }
            heap.swapAt(parent, candidate)
            parent = candidate
        }
    }
    
    public mutating func changeValue(_ i: Int,_ newVal: T) {
        heap[i] = newVal
        if i != 0 && sort(heap[i], heap[parent(i)]) { siftUp(i) }
        else { siftDown(i) }
    }
    
}
