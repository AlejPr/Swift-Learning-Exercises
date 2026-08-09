import Foundation
import Collections

//MARK: - ConcurrentCache
final class ConcurrentCache<Key: Hashable, Value> {
    
    private let queue = DispatchQueue(label: "concurrentCache", attributes: .concurrent)
    private var cache = [Key: Value]()
    
    var count: Int {
        get { queue.sync { return cache.count } }
    }

    func value(for key: Key) -> Value? {
        queue.sync { return self.cache[key] }
    }
    
    func set(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) { self.cache[key] = value }
    }
    
    func removeValue(for key: Key) {
        queue.async(flags: .barrier) { self.cache.removeValue(forKey: key) }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) { self.cache.removeAll() }
    }
    
    /// Reads are sync for convenience, if they were async it would require an escaping closure to be passed into the get function to return a value.
    /// By using a sync call, instead you can block the current thread, switch off to the "Concurrent Cache" queue, and immediately retrieve the value.
    /// Since the cache thread is concurrent there is very little waiting for the sync call (in most cases no waiting unless there is a write call in progress); it is made immediately as long as the hardware has processing power.
    ///
    /// Writes are made asynchronously with a barrier, which causes the queue to wait for all sync functions to complete before starting the write operation.
    /// Each async barrier call in the concurrent queue effectively transforms the queue from a concurrent queue to a serial one; reads are concurrent, writes are serial.
    ///
    /// If writes were synchronous without a barrier, the queue could not guarantee write exclusivity or data race protections as two threads could access the underlying cache at the same time.
    /// Attempting to retrieve a value and write at the same moment would cause a data race as two threads would be spawned with unsafe competing access to the cache.
    /// Reads using a synchronous barrier would be safe, however it would destroy the point of a concurrent cache as all calls would be serial.

    /// - Why does the barrier flag give you writer exclusivity? What is the queue actually doing?
    /// Barrier blocks prevent any additional tasks from being executed on the concurrent queue until all existing tasks have finished, then the barrier runs the submitted task, and subsequently frees up the queue to accept more tasks.
    /// It effectively turns a concurrent queue into a serial queue until the barrier block(s) have finished executing.
    ///
    /// - Reads are sync — doesn't that block the calling thread? Why is that acceptable (or not)?
    /// Yes, in this case it is acceptable because signifcant work that could cause delays are not being performed, and there are no risk of deadlocks or thread hangs.
    ///
    /// - If Value is a class (reference type), does returning it from value(for:) while a concurrent removeAll runs cause a problem? (Think about ARC and what the barrier protects.)
    /// No because removeAll runs serially, any get requests made for the value before calling removeAll is guaranteed to return a reference to the class. Unless the reference stored is weak, the object will outlive its life in the cache after removeAll is called.
    ///
    /// - Could this deadlock? Under what circumstances? (Hint: calling queue.sync from within a block already running on queue.)
    ///  No this could not deadlock.
    ///  Threads deadlock when awaiting on a result from a synchronous task that will never arrive; here there are no methods where that is possible as each function immediately writes or returns a value without awaiting the result of an outside task.
    ///
    
}


//MARK: - Debouncer
final class Debouncer {
    
    private let delayInterval: TimeInterval
    private let queue: DispatchQueue
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delayInterval = delay
        self.queue = queue
    }
    
    func run(_ action: @escaping () -> Void) {
        cancel()
        let workItem = DispatchWorkItem(block: action)
        self.workItem = workItem
        
        queue.asyncAfter(deadline: .now() + self.delayInterval, execute: workItem)
    }
    
    private func cancel() {
        workItem?.cancel()
    }
    
    /// - Why DispatchWorkItem instead of just asyncAfter(deadline:) with a closure?
    /// DispatchWorkItem allows you to cancel a pending task; when asyncAfter is executed, attempting to run a task that has been cancelled immediately returns.
    ///
    /// - Where's the retain cycle in the naive version? Draw the ownership graph: who retains whom?
    /// In the naive version where calls to the debouncer are made, which include references to the viewcontroller inside of them without capturing the reference as weak, the capture retains a reference to the viewcontroller while stored inside of the debouncer.
    /// Thus graph goes: ViewController -> debouncer -> capture -> ViewController. Until another closure is passed into the debouncer that is either weak or does not reference the viewcontroller, the viewcontroller is not allowed to deinitialize because of the stored reference inside of the debouncer's workItem.
    ///
    /// - Does the DispatchWorkItem itself participate in the cycle, or just the captured closure?
    /// The DispatchWorkItem contains a reference to the closure, but the closure itself contains the reference. So by removing any references to the workItem, the closure also loses it's references and is deallocated, which would break the cycle.
    ///
    /// - After you add [weak self], what happens if self is deallocated before the work item fires? Walk through it.
    /// The reference to the WorkItem is lost, which cancels the workItem and prevents it from being executed once asyncAfter is ready to execute the work.
    ///
    /// - Is the Debouncer's stored workItem property a strong reference? Does that matter for the cycle?
    /// Yes it's a strong reference, and it is necessary otherwise the workItem would immediately deallocate and could not be canceled / executed later.
    /// Yes it also matters, because if it was a weak reference the debouncer would not work but it would also not contain a cycle.
    
}



////MARK: - Throttler
final class Throttler {
    
    private let throttleInterval: TimeInterval
    private let queue: DispatchQueue
    private var nextExecutionTime: Date
    
    init(interval: TimeInterval, queue: DispatchQueue = .main) {
        self.throttleInterval = interval
        self.queue = queue
        self.nextExecutionTime = Date().addingTimeInterval(-interval)
    }
    
    func run(_ action: @escaping () -> Void) {
        let curTime = Date()
        guard curTime >= nextExecutionTime else { return }
        nextExecutionTime = curTime.addingTimeInterval(throttleInterval)
        queue.async(execute: action)
    }
    
}



//MARK: - LRU Cache
final class LRUCache<Key: Hashable, Value> {
    
    internal class ListNode {
        let key: Key?
        var value: Value?
        weak var next: ListNode?
        weak var prev: ListNode?
        init(_ key: Key, _ val: Value) { self.key = key; self.value = val }
        init() { self.key = nil; self.value = nil }
    }
    
    private let capacity: Int
    internal var cache = [Key: ListNode]()
    internal var queue = DispatchQueue(label: "lruCache")
    
    //[dummyLast --- dummyFirst]
    internal let dummyTail = ListNode()
    internal let dummyHead = ListNode()
    
    init(capacity: Int) {
        self.capacity = capacity
        dummyTail.next = dummyHead; dummyHead.prev = dummyTail
    }
    
    //Retrieves an existing node from the cache or creates a new one if not present
    //Inserts it at the head of the list, and then checks to see if it's necessary to prune a node from the end of the list
    func setValue(_ value: Value, for key: Key) {
        queue.async { [weak self] in
            let node = self?.removeNode(key) ?? ListNode(key, value)
            node.value = value
            self?.cache[key] = node
            self?.insertAtHead(node)
            self?.prune()
        }
    }
    
    //If the value exists, remove it from the list and send it to the head
    func value(for key: Key) -> Value? {
        queue.sync { [weak self] in
            guard let node = self?.removeNode(key) else { return nil }
            self?.insertAtHead(node)
            return node.value
        }
    }
    
    //[prev - head]
    //[prev | node - head]
    //[prev - node - head]
    private func insertAtHead(_ node: ListNode) {
        let prev = dummyHead.prev
        dummyHead.prev = node
        prev?.next = node
        node.prev = prev; node.next = dummyHead
    }
    
    //[prev - node - next]
    //[prev - ??? - next] | node
    //[prev - next]
    private func removeNode(_ key: Key) -> ListNode? {
        guard let node = cache[key] else { return nil }
        let next = node.next, prev = node.prev
        node.next = nil; node.prev = nil
        next?.prev = prev; prev?.next = next
        return node
    }
    
    //Removes nodes from the tail of the list until dict is no longer above capacity
    private func prune() {
        while cache.count > capacity,
              let leastUsed = dummyTail.next,
                let key = leastUsed.key {
            leastUsed.next?.prev = dummyTail
            dummyTail.next = leastUsed.next
            cache.removeValue(forKey: key)
        }
    }
    
}


//MARK: - Batch Fetcher
final class BatchFetcher {
    
    /// Fetches all URLs concurrently. Calls completion exactly once,
    /// on the main queue, with results in the same order as `urls`.
    /// A failed fetch should produce nil at that index, not abort the batch.
    func fetchAll(_ urls: [URL],
                  using fetcher: @escaping (URL, @escaping (Data?) -> Void) -> Void, //Fetchers execute concurrently?
                  completion: @escaping ([Data?]) -> Void) {
        
        let serialWriteQueue = DispatchQueue(label: "writeQueue")
        let group = DispatchGroup()
        var ans: [Data?] = Array(repeating: nil, count: urls.count)
        
        for fetchRequest in urls.enumerated() {
            group.enter()
            
            fetcher(fetchRequest.element) { res in
                guard let res else { group.leave(); return }
                
                serialWriteQueue.async {
                    ans[fetchRequest.offset] = res
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { completion(ans) }
    }
    
}


//MARK: - Download Scheduler
//Problem with thread explosion
final class DownloadScheduler: @unchecked Sendable {
    
    private let semaphore: DispatchSemaphore
    private let concurrentQueue = DispatchQueue(label: "downloadScheduler", attributes: .concurrent)
    private let writeQueue = DispatchQueue(label: "queueEnforcement")
    private var workItemQueue = Deque<DispatchWorkItem>()
    private let inFlightGroup = DispatchGroup()
    
    init(maxConcurrent: Int) { self.semaphore = DispatchSemaphore(value: maxConcurrent) }

    /// Enqueues work. At most `maxConcurrent` execute simultaneously;
    /// the rest wait their turn in FIFO order.
    @discardableResult
    func schedule(_ work: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem{ work() }
        inFlightGroup.enter()
        writeQueue.sync { [weak self ] in self?.workItemQueue.append(workItem) }
        executeNext()
        return workItem
    }
    
    private func executeNext() {
        concurrentQueue.async { [weak self] in
            guard let self else { return }
            self.semaphore.wait()
            
            let first = self.writeQueue.sync { return self.workItemQueue.popFirst() }
            guard let first = first else {
                self.semaphore.signal()
                return
            }
            
            if !first.isCancelled { first.perform() }
            
            self.inFlightGroup.leave()
            self.semaphore.signal()
        }
    }

    /// Cancels all pending (not-yet-started) work and calls `onDrained`
    /// once any in-flight work finishes.
    func cancelAll(onDrained: @escaping () -> Void) {
        writeQueue.sync { [weak self] in
            while let first = self?.workItemQueue.popFirst() {
                first.cancel()
                self?.inFlightGroup.leave()
            }
        }
        
        inFlightGroup.notify(queue: .main, execute: onDrained)
    }
}



//MARK: - Combine Style Event Bus
final class EventBus<Event> {
    
    private var listeners = [UUID: (Event) -> Void]()
    private let writeQueue = DispatchQueue(label: "busQueue")
    
    /// Registers a handler. The subscription stays alive exactly as long
    /// as the returned token does: deallocate the token, and the handler
    /// is removed automatically — no explicit unsubscribe call.
    func subscribe(_ handler: @escaping (Event) -> Void) -> SubscriptionToken {
        let token = SubscriptionToken { [weak self] id in
            _ = self?.writeQueue.sync { self?.listeners.removeValue(forKey: id) }
        }
        
        writeQueue.sync { listeners[token.id] = handler }
        return token
    }

    /// Delivers the event to all live subscribers, on the caller's thread.
    func publish(_ event: Event) {
        let snapshot = writeQueue.sync { return self.listeners.values }
        for handler in snapshot { handler(event) }
    }
    
    func unregister(_ id: UUID) {
        writeQueue.async { [weak self] in self?.listeners.removeValue(forKey: id) }
    }
        
}

final class SubscriptionToken {
    
    let id = UUID()
    var unregister: (UUID) -> Void
    
    init(_ unregister: @escaping (UUID) -> Void) { self.unregister = unregister }
    deinit { unregister(id) }
    
}



//MARK: - Rate Limiter
final class GCDRateLimiter {
    
    internal var queue = Deque<DispatchWorkItem>()
    internal var timer: DispatchSourceTimer?
    internal let permit: Int
    internal var capacity: Int
    
    internal let serialQueue = DispatchQueue(label: "GCDRateLimiterSerialQueue")
    internal let executionQueue = DispatchQueue(label: "GCDRateLimiterConcurrentQueue", attributes: .concurrent)
    internal var paused: Int = 0
    
    /// Allows at most `permits` executions per `interval`, refilled steadily.
    //NOTE: Init should be optional in case permits is 0 or less.
    init(permits: Int, per interval: TimeInterval) {
        self.permit = permits
        self.capacity = permits
        self.timer = DispatchSource.makeTimerSource()
        let interval = DispatchTimeInterval.milliseconds(Int(interval * 1000))
        
        timer?.schedule(deadline: .now() + interval, repeating: interval)
        timer?.setEventHandler(handler: DispatchWorkItem { [weak self] in self?.timerFired() })
        timer?.activate()
    }

    /// Runs `work` as soon as a permit is available; FIFO when none are.
    func execute(_ work: @escaping () -> Void) {
        serialQueue.sync { queue.append(DispatchWorkItem(block: work)) }
        executeNext()
    }
    
    //Adds 1 point of capacity and calls the next work item
    private func timerFired() {
        serialQueue.sync { self.capacity = min(capacity + 1, permit) }
        executeNext()
    }
    
    //Checks if there's capacity, if the timer is paused, and if both condtions pass then executes the next block
    private func executeNext() {
        let (capacity, isPaused) = serialQueue.sync { (self.capacity, self.paused) }
        guard capacity > 0 && isPaused == 0 else { return }
        
        //Permission to continue execution
        let next = serialQueue.sync { self.queue.popFirst() }
        guard let next else { return }
        serialQueue.sync { self.capacity -= 1 }
        executionQueue.async(execute: next)
    }
    
    
    /// Pauses permit consumption; queued work waits. Must be balanced
    /// with resume(). Calling pause twice then resume once stays paused.
    func pause() {
        serialQueue.sync {
            timer?.suspend()
            self.paused += 1
        }
    }
    
    
    func resume() {
        serialQueue.sync {
            guard self.paused > 0 else { return } //Prevent over resume crash
            self.paused -= 1
            timer?.resume()
        }
        executeNext()
    }
    
    //
    deinit {
        serialQueue.sync {
            for _ in stride(from: 1, through: paused, by: 1) { timer?.resume() }
            timer?.cancel()
            timer = nil
        }
    }
    
}
