import Foundation


public actor TTLCache<Key: Hashable & Sendable, Value: Sendable> {
    
    private var stored = [Key: (value: Value, expiration: ContinuousClock.Instant)]()
    private var inFlight = [Key: Task<Value, any Error>]()
    private var defaultTTL: Duration
    private var clock: ContinuousClock
    
    init(defaultTTL: Duration, clock: ContinuousClock = ContinuousClock()) {
        self.defaultTTL = defaultTTL
        self.clock = clock
    }
    
    /// Fetch a value, calling `loader` if the key is missing or expired.
    /// Concurrent calls for the same key while a load is in progress
    /// should share the result — don't run loader twice.
    func value(
        for key: Key,
        loader: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        if let value = stored[key] {
            if value.expiration >= clock.now { return value.value }
            stored.removeValue(forKey: key)
        }
        
        if inFlight[key] == nil {
            let task = Task {
                do { return try await loader() }
                catch is CancellationError { throw TTLCacheError.cancelled }
                catch { throw TTLCacheError.failedToLoad }
            }
            
            inFlight[key] = task
        }
        
        switch await inFlight[key]!.result {
            
        case .success(let res):
            stored[key] = (value: res, expiration: ContinuousClock.now + defaultTTL)
            return res
            
        case .failure(let err as TTLCacheError):
            guard err == .cancelled,
                  let existing = stored[key],
                  existing.expiration >= clock.now else { throw err }
            return existing.value
            
        case .failure(let err): throw err
        }
    }
    
    /// Insert or replace a value with an explicit TTL.
    func set(_ value: Value, for key: Key, ttl: Duration? = nil) {
        stored[key] = (value: value, expiration: ContinuousClock.now + (ttl ?? defaultTTL))
        if let inflight = inFlight[key] { inflight.cancel() }
    }
    
    /// Remove a single entry.
    func invalidate(key: Key) {
        stored.removeValue(forKey: key)
        for task in inFlight {  }
    }
    
    /// Remove all entries.
    func invalidateAll() {
        stored.removeAll()
    }
    
    /// Number of non-expired entries currently in the cache.
    /// Expired entries should not be counted (and should be cleaned up).
    func count() -> Int {
        for key in stored.keys { cleanUp(for: key) }
        return stored.count
    }
    
    private func cleanUp(for key: Key) {
        if let expiration = stored[key]?.expiration,
           expiration <= clock.now { stored.removeValue(forKey: key) }
    }
}

public enum TTLCacheError: Error {
    case failedToLoad
    case cancelled
}
