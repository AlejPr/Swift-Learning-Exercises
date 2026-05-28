import Foundation


public actor TTLCache<Key: Hashable & Sendable, Value: Sendable> {
    
    private var stored = [Key: (value: Value, expiration: ContinuousClock.Instant)]()
    private var inFlight = [Key: Task<Value, any Error>]()
    private let defaultTTL: Duration
    private let clock: ContinuousClock
    
    init(defaultTTL: Duration, clock: ContinuousClock = ContinuousClock()) {
        self.defaultTTL = defaultTTL
        self.clock = clock
    }
    
    /// Fetch a value, calling `loader` if the key is missing or expired.
    /// Concurrent calls for the same key while a load is in progress
    /// should share the result — don't run loader twice.
    public func value(
        for key: Key,
        loader: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        if let value = stored[key] {
            if value.expiration >= clock.now { return value.value }
            stored.removeValue(forKey: key)
        }
        
        let task: Task<Value, any Error>
        if let existing = inFlight[key] { task = existing }
        else {
            task = Task {
                do { return try await loader() }
                catch is CancellationError { throw TTLCacheError.cancelled }
                catch { throw TTLCacheError.failedToLoad(underlyingError: error) }
            }
            
            inFlight[key] = task
        }
        
        let result = await task.result
        inFlight.removeValue(forKey: key)
        switch result {
            
        case .success(let res):
            stored[key] = (value: res, expiration: clock.now + defaultTTL)
            return res
            
        case .failure(let err as TTLCacheError):
            switch err {
            case .cancelled:
                guard let existing = stored[key], existing.expiration >= clock.now else { throw err }
                return existing.value
            default: throw err
            }

        case .failure(let err): throw err
        }
    }
    
    /// Insert or replace a value with an explicit TTL.
    public func set(_ value: Value, for key: Key, ttl: Duration? = nil) {
        stored[key] = (value: value, expiration: clock.now + (ttl ?? defaultTTL))
        if let inflight = inFlight[key] { inflight.cancel() }
    }
    
    /// Remove a single entry.
    public func invalidate(key: Key) {
        stored.removeValue(forKey: key)
        inFlight[key]?.cancel()
        inFlight.removeValue(forKey: key)
    }
    
    /// Remove all entries.
    public func invalidateAll() {
        stored.removeAll()
        for task in inFlight { task.value.cancel() }
        inFlight.removeAll()
    }
    
    /// Number of non-expired entries currently in the cache.
    /// Expired entries should not be counted (and should be cleaned up).
    public func count() -> Int {
        let now = clock.now
        return stored.values.filter { $0.expiration > now }.count
    }
    
    private func cleanUp(for key: Key) {
        if let expiration = stored[key]?.expiration,
           expiration <= clock.now { stored.removeValue(forKey: key) }
    }
}

public enum TTLCacheError: Error {
    case failedToLoad(underlyingError: Error)
    case cancelled
}
