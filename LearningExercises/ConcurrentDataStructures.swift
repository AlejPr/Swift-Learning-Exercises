import Foundation
import Collections


//MARK: - Mutex
public actor AsyncMutex {
    
    private var currentKey: UUID?
    private var queue = Deque<CheckedContinuation<UUID, Never>>()
    
    enum AsyncMutexError: Error {
        case invalidKey
    }
    
    public func lock() async -> UUID {
        if currentKey == nil {
            let newKey = UUID()
            currentKey = newKey
            return newKey
        }
        
        return await withCheckedContinuation { cont in queue.append(cont) }
    }
    
    public func unlock(_ key: UUID) async throws {
        if let storedKey = currentKey, storedKey != key { throw AsyncMutexError.invalidKey }
        currentKey = nil
        
        guard let next = queue.popFirst() else { return }
        let newKey = UUID()
        currentKey = newKey
        next.resume(returning: newKey)
    }
    
}



//MARK: - Semaphore
public actor AsyncSemaphore {
    
    private let limit: Int
    private var count = 0
    private var queue = Deque<CheckedContinuation<(), Never>>()
    
    public init(limit: Int) { self.limit = limit }
    
    public func acquireSlot() async {
        if count < limit { count += 1; return }
        
        await withCheckedContinuation { cont in queue.append(cont) }
    }
    
    public func releaseSlot() async {
        if let first = queue.popFirst() {
            first.resume()
            return
        }
        
        count -= 1
    }
    
}


//MARK: - Rate Limiter
public actor RateLimiter {
    
    let maxOperations: Int
    let interval: Duration
    private var queue = Deque<Date>()
    
    public init(maxOperations: Int, per interval: Duration) { self.maxOperations = maxOperations; self.interval = interval }
    
    public func acquire() async {
        cleanUp()
        if queue.count < maxOperations { return queue.append(Date()) }
                
        //Sleep until rate limit has refreshed
        let wakeUpTime = TimeInterval(interval.components.seconds) - queue.first!.timeIntervalSinceNow
        try? await Task.sleep(until: .now.advanced(by: Duration.seconds(wakeUpTime)))
        
    }
    
    private func cleanUp() {
        let curr = Date()
        while !queue.isEmpty,
                queue.first!.addingTimeInterval(TimeInterval(interval.components.seconds)) <= curr {
            queue.removeFirst()
        }
    }
    
}
