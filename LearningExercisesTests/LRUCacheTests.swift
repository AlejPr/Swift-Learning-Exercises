import Testing
import Foundation
@testable import LearningExercises

// Expected API under test:
//
// final class LRUCache<Key: Hashable, Value> {
//     init(capacity: Int)
//     func value(for key: Key) -> Value?
//     func setValue(_ value: Value, for key: Key)
// }

@Suite("LRUCache")
struct LRUCacheTests {

    // MARK: - Basic correctness

    @Test func setThenGetReturnsValue() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, for: "a")
        #expect(cache.value(for: "a") == 1)
    }

    @Test func missingKeyReturnsNil() {
        let cache = LRUCache<String, Int>(capacity: 2)
        #expect(cache.value(for: "nope") == nil)
    }

    @Test func updatingExistingKeyOverwritesValueWithoutEvicting() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, for: "a")
        cache.setValue(2, for: "b")
        cache.setValue(99, for: "a")  // update, not insert — must not evict "b"
        #expect(cache.value(for: "a") == 99)
        #expect(cache.value(for: "b") == 2)
    }

    // MARK: - Eviction policy (the LeetCode 146 behaviors)

    @Test func evictsLeastRecentlyUsedOnOverflow() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, for: "a")
        cache.setValue(2, for: "b")
        cache.setValue(3, for: "c")  // evicts "a"
        #expect(cache.value(for: "a") == nil)
        #expect(cache.value(for: "b") == 2)
        #expect(cache.value(for: "c") == 3)
    }

    @Test func readPromotesRecency() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, for: "a")
        cache.setValue(2, for: "b")
        _ = cache.value(for: "a")    // "a" is now most recent
        cache.setValue(3, for: "c")  // should evict "b", not "a"
        #expect(cache.value(for: "a") == 1)
        #expect(cache.value(for: "b") == nil)
    }

    @Test func updatePromotesRecency() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, for: "a")
        cache.setValue(2, for: "b")
        cache.setValue(10, for: "a") // updating "a" promotes it
        cache.setValue(3, for: "c")  // should evict "b"
        #expect(cache.value(for: "a") == 10)
        #expect(cache.value(for: "b") == nil)
    }

    @Test func capacityOneBehavesCorrectly() {
        let cache = LRUCache<String, Int>(capacity: 1)
        cache.setValue(1, for: "a")
        cache.setValue(2, for: "b")
        #expect(cache.value(for: "a") == nil)
        #expect(cache.value(for: "b") == 2)
    }

    // MARK: - Performance shape (O(1) smoke test, not a proof)
    // Swift Testing has no `measure`; a time limit catches gross blowups.
    // If you used Array.removeFirst() for eviction, this should trip.

    @Test(.timeLimit(.minutes(1)))
    func manyOperationsCompleteQuickly() {
        let cache = LRUCache<Int, Int>(capacity: 1_000)
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for i in 0..<50_000 {
                cache.setValue(i, for: i % 2_000)
                _ = cache.value(for: (i &* 7) % 2_000)
            }
        }
        // Generous bound; O(1) impls finish in well under a second.
        #expect(elapsed < .seconds(5), "100k ops took \(elapsed) — check for O(n) hiding in eviction or promotion")
    }

    // MARK: - Thread safety
    // Run with Thread Sanitizer ON (Scheme > Diagnostics > TSan).
    // Passing without TSan proves little; TSan turns silent races into failures.

    @Test func concurrentReadsAndWritesDoNotCrashOrRace() {
        let cache = LRUCache<Int, Int>(capacity: 64)
        for i in 0..<64 { cache.setValue(i, for: i) }

        DispatchQueue.concurrentPerform(iterations: 10_000) { i in
            if i % 3 == 0 {
                cache.setValue(i, for: i % 200)   // writes, with evictions
            } else {
                _ = cache.value(for: i % 200)     // "reads" that promote
            }
        }
        // Reaching here without a crash/TSan report is the assertion.
        // Also verify the cache is still functional afterwards:
        cache.setValue(-1, for: -1)
        #expect(cache.value(for: -1) == -1)
    }

    @Test func concurrentReadsOfSameKeyAllSucceed() {
        // Hammers the trap from our discussion: many simultaneous reads of
        // one key all trigger recency promotion of the SAME node. If your
        // promotion isn't exclusive, the linked list corrupts here.
        let cache = LRUCache<String, Int>(capacity: 8)
        cache.setValue(42, for: "hot")
        for i in 0..<7 { cache.setValue(i, for: "filler\(i)") }

        let counter = AtomicCounter()
        DispatchQueue.concurrentPerform(iterations: 5_000) { _ in
            if cache.value(for: "hot") == 42 { counter.increment() }
        }
        #expect(counter.value == 5_000, "every read of a present key must return its value")
    }

    @Test func concurrentInsertsNeverExceedCapacity() {
        let capacity = 16
        let cache = LRUCache<Int, Int>(capacity: capacity)

        DispatchQueue.concurrentPerform(iterations: 2_000) { i in
            cache.setValue(i, for: i)
        }

        // We can't inspect count directly with this API, so probe:
        // at most `capacity` of the inserted keys may still be present.
        var survivors = 0
        for i in 0..<2_000 where cache.value(for: i) != nil { survivors += 1 }
        #expect(survivors <= capacity,
                "two threads passing the capacity check simultaneously lets the cache overgrow — eviction must be atomic with insertion")
        #expect(survivors > 0, "cache should not have lost everything")
    }

    // MARK: - Memory management

    @Test func evictedValuesAreReleased() {
        // Catches the next/prev strong-strong retain cycle: an evicted
        // node trapped in a cycle never deallocates, so its value leaks.
        let cache = LRUCache<String, Canary>(capacity: 1)
        weak var weakCanary: Canary?

        autoreleasepool {
            let canary = Canary()
            weakCanary = canary
            cache.setValue(canary, for: "doomed")
            cache.setValue(Canary(), for: "replacement") // evicts "doomed"
        }

        // Eviction may happen via an async barrier write, so the node is
        // released when that block executes — not synchronously. Poll with
        // a deadline: deferred release passes in milliseconds; a genuine
        // retain cycle still fails after the timeout.
        #expect(eventually { weakCanary == nil },
                "evicted value was never deallocated — check for a retain cycle in your node links")
    }

    @Test func cacheDeinitReleasesAllValues() {
        // A chain of strong next + strong prev pointers keeps every node
        // alive even after the cache itself is gone.
        weak var weakA: Canary?
        weak var weakB: Canary?

        autoreleasepool {
            let cache = LRUCache<String, Canary>(capacity: 4)
            let a = Canary(), b = Canary()
            weakA = a; weakB = b
            cache.setValue(a, for: "a")
            cache.setValue(b, for: "b")
            _ = cache.value(for: "a") // touch the list so links exist both ways
        } // cache deallocates here
        

        // Same async-release tolerance as above: pending queue work may
        // briefly keep nodes alive after the cache itself is gone.
        #expect(eventually { weakA == nil }, "node chain leaked after cache deinit")
        #expect(eventually { weakB == nil }, "node chain leaked after cache deinit")
    }
}

// MARK: - Test helpers

private final class Canary {}

/// Polls `condition` until it's true or `timeout` elapses.
/// Use for assertions about asynchronous side effects (e.g. deallocation
/// deferred by an async barrier write). Returns fast on success, so the
/// happy path costs milliseconds, not the full timeout.
private func eventually(within timeout: Duration = .seconds(2),
                        _ condition: () -> Bool) -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if condition() { return true }
        usleep(10_000) // 10 ms between polls
    }
    return condition()
}

/// Minimal thread-safe counter so the tests themselves don't race.
private final class AtomicCounter: @unchecked Sendable {
    private var count = 0
    private let lock = NSLock()
    func increment() { lock.lock(); count += 1; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}
