


struct LeetcodePQ<T> {
    private var heap: [T]
    private let sort: (T, T) -> Bool
    
    init(sort: @escaping (T, T) -> Bool) {
        self.heap = []
        self.sort = sort
    }

    var isEmpty: Bool {
        heap.isEmpty
    }

    mutating func enqueue(_ element: T) {
        heap.append(element)
        siftUp(heap.count - 1)
    }

    mutating func dequeue() -> T? {
        guard !heap.isEmpty else { return nil }
        if heap.count == 1 {
            return heap.removeFirst()
        } else {
            let first = heap[0]
            heap[0] = heap.removeLast()
            siftDown(0)
            return first
        }
    }

    private mutating func siftUp(_ index: Int) {
        var child = index
        var parent = (child - 1) / 2
        while child > 0 && sort(heap[child], heap[parent]) {
            heap.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(_ index: Int) {
        var parent = index
        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var candidate = parent

            if left < heap.count && sort(heap[left], heap[candidate]) {
                candidate = left
            }
            if right < heap.count && sort(heap[right], heap[candidate]) {
                candidate = right
            }
            if candidate == parent {
                return
            }
            heap.swapAt(parent, candidate)
            parent = candidate
        }
    }
}



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
