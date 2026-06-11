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




@Suite("BatchFetcher")
struct BatchFetcherTests {

    // MARK: - Fixtures

    private func makeURLs(_ count: Int) -> [URL] {
        (0..<count).map { URL(string: "https://example.com/\($0)")! }
    }

    /// Encodes the URL's last path component so each result is traceable
    /// back to the URL that produced it.
    private func payload(for url: URL) -> Data {
        Data(url.lastPathComponent.utf8)
    }

    /// Bridges the callback API into async so tests can await the batch.
    private func runBatch(
        _ urls: [URL],
        fetcher: @escaping (URL, @escaping (Data?) -> Void) -> Void
    ) async -> [Data?] {
        await withCheckedContinuation { continuation in
            BatchFetcher().fetchAll(urls, using: fetcher) { results in
                continuation.resume(returning: results)
            }
        }
    }

    // MARK: - Ordering

    @Test(.timeLimit(.minutes(1)))
    func resultsMatchInputOrderWhenFetchesCompleteOutOfOrder() async {
        // Deterministically hostile scheduling: collect every callback,
        // then fire them in REVERSE order from background threads. If the
        // implementation appends results in completion order instead of
        // writing to the original index, this fails every time — no luck.
        let urls = makeURLs(10)
        let pending = Locked<[(URL, (Data?) -> Void)]>([])

        let results = await runBatch(urls) { url, callback in
            let firePoint: [(URL, (Data?) -> Void)]? = pending.mutate {
                $0.append((url, callback))
                return $0.count == urls.count ? $0 : nil
            }
            if let all = firePoint {
                for (u, cb) in all.reversed() {
                    DispatchQueue.global().async { cb(self.payload(for: u)) }
                }
            }
        }

        #expect(results.count == urls.count)
        for (i, url) in urls.enumerated() {
            #expect(results[i] == payload(for: url),
                    "result at index \(i) does not correspond to urls[\(i)] — results must be written by original index, not arrival order")
        }
    }

    // MARK: - Failure handling

    @Test(.timeLimit(.minutes(1)))
    func failedFetchProducesNilAtItsIndexWithoutAbortingBatch() async {
        let urls = makeURLs(6)
        let failingIndices: Set<Int> = [1, 4]

        let results = await runBatch(urls) { url, callback in
            DispatchQueue.global().async {
                let index = Int(url.lastPathComponent)!
                callback(failingIndices.contains(index) ? nil : self.payload(for: url))
            }
        }

        #expect(results.count == urls.count, "a failure must not shrink or abort the batch")
        for i in urls.indices {
            if failingIndices.contains(i) {
                #expect(results[i] == nil, "failed fetch should yield nil at index \(i)")
            } else {
                #expect(results[i] == payload(for: urls[i]))
            }
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func allFailuresStillCompletesWithAllNils() async {
        let urls = makeURLs(4)
        let results = await runBatch(urls) { _, callback in
            DispatchQueue.global().async { callback(nil) }
        }
        #expect(results == [nil, nil, nil, nil])
    }

    // MARK: - Completion contract

    @Test(.timeLimit(.minutes(1)))
    func completionFiresOnMainQueue() async {
        let urls = makeURLs(3)
        let onMain = Locked(false)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            BatchFetcher().fetchAll(urls, using: { url, callback in
                DispatchQueue.global().async { callback(self.payload(for: url)) }
            }, completion: { _ in
                onMain.mutate { $0 = Thread.isMainThread }
                continuation.resume()
            })
        }

        #expect(onMain.read { $0 },
                "completion must be delivered on the main queue (group.notify(queue: .main))")
    }

    @Test(.timeLimit(.minutes(1)))
    func completionFiresExactlyOnceUnderConcurrentCompletions() async {
        // All fetches complete simultaneously from different threads —
        // an enter/leave imbalance or a notify registered per-fetch
        // shows up here as 0 or 2+ completion calls.
        let urls = makeURLs(32)
        let completionCalls = Locked(0)
        let gate = DispatchGroup()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            gate.enter() // released after a settling delay below
            BatchFetcher().fetchAll(urls, using: { url, callback in
                DispatchQueue.global().async { callback(self.payload(for: url)) }
            }, completion: { _ in
                completionCalls.mutate { $0 += 1 }
            })
            // Give any erroneous second invocation time to land before judging.
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                gate.leave()
            }
            gate.notify(queue: .global()) { continuation.resume() }
        }

        #expect(completionCalls.read { $0 } == 1,
                "completion ran \(completionCalls.read { $0 }) times — must be exactly once")
    }

    @Test(.timeLimit(.minutes(1)))
    func emptyInputStillCallsCompletionWithEmptyArray() async {
        // The classic DispatchGroup edge case: zero enters means notify
        // fires immediately. An implementation that only registers notify
        // inside the fetch loop, or waits for a first leave, hangs here —
        // which is why this test carries a time limit.
        let results = await runBatch([]) { _, _ in
            Issue.record("fetcher must not be invoked for an empty batch")
        }
        #expect(results.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func duplicateURLsEachGetTheirOwnResult() async {
        let url = URL(string: "https://example.com/dup")!
        let urls = [url, url, url]
        let invocations = Locked(0)

        let results = await runBatch(urls) { u, callback in
            invocations.mutate { $0 += 1 }
            DispatchQueue.global().async { callback(self.payload(for: u)) }
        }

        #expect(invocations.read { $0 } == 3, "fetcher should be invoked once per element, even for duplicate URLs")
        #expect(results.count == 3)
        #expect(results.allSatisfy { $0 == payload(for: url) })
    }

    // MARK: - Concurrency shape

    @Test(.timeLimit(.minutes(1)))
    func fetchesRunInParallelNotSerially() async {
        // 8 fetches, each taking ~150ms. Parallel: wall clock ≈ 150ms.
        // Serial (e.g. waiting on each fetch before starting the next):
        // ≈ 1.2s. The 600ms threshold cleanly separates the two even on
        // a noisy CI box.
        let urls = makeURLs(8)
        let clock = ContinuousClock()

        let elapsed = await clock.measure {
            _ = await runBatch(urls) { url, callback in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
                    callback(self.payload(for: url))
                }
            }
        }

        #expect(elapsed < .milliseconds(600),
                "8 × 150ms fetches took \(elapsed) — they appear to run serially, not concurrently")
    }

    @Test(.timeLimit(.minutes(1)))
    func manySimultaneousCompletionsDoNotCorruptResults() async {
        // Stress the shared results storage: 200 fetches all completing
        // at once from the global pool. Run with Thread Sanitizer ON —
        // an unsynchronized `results[i] = data` is a race TSan will flag
        // even when the values happen to come out right.
        let urls = makeURLs(200)

        let results = await runBatch(urls) { url, callback in
            DispatchQueue.global().async { callback(self.payload(for: url)) }
        }

        #expect(results.count == urls.count)
        for (i, url) in urls.enumerated() {
            #expect(results[i] == payload(for: url))
        }
    }

    // MARK: - Memory management

    @Test(.timeLimit(.minutes(1)))
    func completionClosureIsReleasedAfterBatchFinishes() async {
        // Whatever the completion captured (in real code: a view
        // controller) must be released once the batch is done — not
        // pinned by stored state on the fetcher or the group.
        weak var weakCanary: Canary?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            autoreleasepool {
                let canary = Canary()
                weakCanary = canary
                BatchFetcher().fetchAll(makeURLs(4), using: { url, callback in
                    DispatchQueue.global().async { callback(self.payload(for: url)) }
                }, completion: { [canary] _ in
                    _ = canary // completion strongly captures it, as a VC would be
                    continuation.resume()
                })
            }
        }

        #expect(eventually { weakCanary == nil },
                "completion closure (and its captures) leaked after the batch finished")
    }

    @Test(.timeLimit(.minutes(1)))
    func slowFetchDoesNotPreventEventualRelease() async {
        // Simulates the dismissed-view-controller scenario: the batch is
        // in flight, nobody holds the BatchFetcher, one fetch is slow.
        // Captures may legitimately live until the batch completes — but
        // not beyond it.
        weak var weakCanary: Canary?
        let done = Locked(false)

        autoreleasepool {
            let canary = Canary()
            weakCanary = canary
            BatchFetcher().fetchAll(makeURLs(2), using: { url, callback in
                let delay: TimeInterval = url.lastPathComponent == "0" ? 0.01 : 0.3
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    callback(self.payload(for: url))
                }
            }, completion: { [canary] _ in
                _ = canary
                done.mutate { $0 = true }
            })
        }

        // Mid-flight it's fine (arguably correct) for captures to be alive.
        #expect(eventually(within: .seconds(2)) { done.read { $0 } },
                "batch never completed — did the fetcher deallocate out from under its own work?")
        #expect(eventually { weakCanary == nil },
                "captures must be released promptly once the last fetch lands")
    }
}


/// Minimal lock-protected box so the tests themselves don't race.
private final class Locked<T>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()
    init(_ value: T) { self.value = value }
    func read<R>(_ body: (T) -> R) -> R {
        lock.lock(); defer { lock.unlock() }
        return body(value)
    }
    @discardableResult
    func mutate<R>(_ body: (inout T) -> R) -> R {
        lock.lock(); defer { lock.unlock() }
        return body(&value)
    }
}


//MARK: - Download Scheduler Tests
@Suite("DownloadScheduler")
struct DownloadSchedulerTests {
 
    // MARK: - Basic execution
 
    @Test(.timeLimit(.minutes(1)))
    func scheduledWorkExecutes() async {
        let scheduler = DownloadScheduler(maxConcurrent: 2)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            scheduler.schedule { c.resume() }
        }
        // Reaching here is the assertion; the time limit catches a hang.
    }
 
    @Test(.timeLimit(.minutes(1)))
    func allScheduledWorkEventuallyRuns() async {
        let scheduler = DownloadScheduler(maxConcurrent: 3)
        let completed = Locked(0)
        let total = 20
 
        for _ in 0..<total {
            scheduler.schedule {
                usleep(5_000) // 5ms of "work"
                completed.mutate { $0 += 1 }
            }
        }
 
        #expect(eventually(within: .seconds(5)) { completed.read { $0 } == total },
                "only \(completed.read { $0 })/\(total) tasks ran — work is being dropped or a permit leaked")
    }
 
    // MARK: - Concurrency cap
 
    @Test(.timeLimit(.minutes(1)))
    func neverExceedsMaxConcurrent() async {
        let maxConcurrent = 3
        let scheduler = DownloadScheduler(maxConcurrent: maxConcurrent)
        let inFlight = Locked(0)
        let highWater = Locked(0)
        let completed = Locked(0)
        let total = 15
 
        for _ in 0..<total {
            scheduler.schedule {
                let now = inFlight.mutate { $0 += 1; return $0 }
                highWater.mutate { $0 = max($0, now) }
                usleep(30_000) // 30ms — long enough that violations overlap
                inFlight.mutate { $0 -= 1 }
                completed.mutate { $0 += 1 }
            }
        }
 
        #expect(eventually(within: .seconds(5)) { completed.read { $0 } == total })
        let peak = highWater.read { $0 }
        #expect(peak <= maxConcurrent,
                "observed \(peak) tasks running simultaneously — the semaphore gate is not holding")
        #expect(peak > 1,
                "tasks never overlapped at all — the scheduler appears fully serial, not capped-concurrent")
    }
 
    // MARK: - FIFO ordering of pending work
 
    @Test(.timeLimit(.minutes(1)))
    func pendingWorkRunsInFIFOOrder() async {
        // With maxConcurrent = 1, execution order must equal schedule order.
        let scheduler = DownloadScheduler(maxConcurrent: 1)
        let order = Locked<[Int]>([])
        let total = 10
 
        for i in 0..<total {
            scheduler.schedule {
                order.mutate { $0.append(i) }
            }
        }
 
        #expect(eventually(within: .seconds(5)) { order.read { $0.count } == total })
        #expect(order.read { $0 } == Array(0..<total),
                "execution order \(order.read { $0 }) — pending work must run FIFO")
    }
 
    // MARK: - schedule() must not block the caller
 
    @Test(.timeLimit(.minutes(1)))
    func scheduleReturnsImmediatelyWhenSaturated() async {
        // The "which thread calls wait()" question. If schedule() blocks the
        // caller's thread on the semaphore, this test takes ~300ms+ and the
        // elapsed check fails. Blocking the caller is the design that, from
        // the main thread, freezes the UI — and from worker threads, starves
        // the pool (thread explosion).
        let scheduler = DownloadScheduler(maxConcurrent: 1)
        let gate = DispatchSemaphore(value: 0)
 
        scheduler.schedule { gate.wait() } // occupies the only slot
 
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0..<5 {
                scheduler.schedule { } // no free slot — must still return fast
            }
        }
        gate.signal() // unblock so the suite can finish cleanly
 
        #expect(elapsed < .milliseconds(100),
                "schedule() took \(elapsed) while saturated — it must enqueue and return, not block the caller on the semaphore")
    }
 
    // MARK: - Cancellation semantics
 
    @Test(.timeLimit(.minutes(1)))
    func cancelAllSkipsPendingButFinishesInFlight() async {
        let scheduler = DownloadScheduler(maxConcurrent: 1)
        let inFlightGate = DispatchSemaphore(value: 0)
        let inFlightFinished = Locked(false)
        let pendingRan = Locked(false)
        let drained = Locked(false)
 
        // Occupy the single slot with controllable work — and WAIT until it
        // has provably STARTED. Without this handshake, cancelAll can win
        // the race against the worker that dequeues this task, find it
        // still pending, and (correctly, per spec!) cancel it — firing
        // drained immediately. Scheduled-first is not the same as started.
        let started = DispatchSemaphore(value: 0)
        scheduler.schedule {
            started.signal()
            inFlightGate.wait()
            inFlightFinished.mutate { $0 = true }
        }
        started.wait() // now "in-flight" is a fact, not an assumption
        // These can never have started.
        for _ in 0..<4 {
            scheduler.schedule { pendingRan.mutate { $0 = true } }
        }
 
        scheduler.cancelAll { drained.mutate { $0 = true } }
 
        // Drained must NOT fire while in-flight work is still running.
        usleep(100_000) // 100ms
        #expect(drained.read { $0 } == false,
                "onDrained fired while in-flight work was still executing")
 
        inFlightGate.signal() // let the in-flight task finish
 
        #expect(eventually { drained.read { $0 } },
                "onDrained never fired after in-flight work completed")
        #expect(inFlightFinished.read { $0 },
                "in-flight work should run to completion, not be killed mid-flight")
        #expect(pendingRan.read { $0 } == false,
                "pending (never-started) work executed despite cancelAll")
    }
 
    @Test(.timeLimit(.minutes(1)))
    func cancelAllWithNothingInFlightDrainsImmediately() async {
        let scheduler = DownloadScheduler(maxConcurrent: 2)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            scheduler.cancelAll { c.resume() }
        }
        // Mirrors the empty-batch DispatchGroup case: zero in-flight work
        // means drained fires immediately. A hang here means onDrained
        // waits for a leave() that will never come.
    }
 
    // MARK: - The core trap: cancelled work must not leak semaphore permits
 
    @Test(.timeLimit(.minutes(1)))
    func schedulerStillWorksAfterCancellation() async {
        // If a cancelled-before-start work item never signals (or its skip
        // path forgets to), permits leak and the scheduler silently
        // deadlocks after a few cancels. This schedules, cancels, then
        // demands FULL throughput again — repeatedly, to bleed out every
        // permit if the bug exists.
        let maxConcurrent = 2
        let scheduler = DownloadScheduler(maxConcurrent: maxConcurrent)
 
        for round in 0..<3 {
            // Saturate and pile up pending work.
            let gate = DispatchSemaphore(value: 0)
            for _ in 0..<maxConcurrent {
                scheduler.schedule { gate.wait() }
            }
            for _ in 0..<6 {
                scheduler.schedule { } // pending — will be cancelled
            }
 
            let drained = Locked(false)
            scheduler.cancelAll { drained.mutate { $0 = true } }
            for _ in 0..<maxConcurrent { gate.signal() }
            #expect(eventually { drained.read { $0 } }, "drain hung on round \(round)")
 
            // Now demand full concurrency again.
            let completed = Locked(0)
            let inFlight = Locked(0)
            let highWater = Locked(0)
            for _ in 0..<6 {
                scheduler.schedule {
                    let now = inFlight.mutate { $0 += 1; return $0 }
                    highWater.mutate { $0 = max($0, now) }
                    usleep(20_000)
                    inFlight.mutate { $0 -= 1 }
                    completed.mutate { $0 += 1 }
                }
            }
            #expect(eventually(within: .seconds(5)) { completed.read { $0 } == 6 },
                    "round \(round): work stalled after cancelAll — a semaphore permit leaked during cancellation")
            #expect(highWater.read { $0 } == maxConcurrent,
                    "round \(round): peak concurrency dropped to \(highWater.read { $0 })/\(maxConcurrent) — permits are bleeding away one cancel at a time")
        }
    }
 
    // MARK: - Memory management
 
    @Test(.timeLimit(.minutes(1)))
    func cancelledWorkReleasesItsCapturesPromptly() async {
        // Pending work items capture their closures (in real code: a view
        // controller). After cancelAll, those captures must be released —
        // not held until some queue drains at its leisure.
        let scheduler = DownloadScheduler(maxConcurrent: 1)
        let gate = DispatchSemaphore(value: 0)
        weak var weakCanary: Canary?
 
        scheduler.schedule { gate.wait() } // occupy the slot
 
        autoreleasepool {
            let canary = Canary()
            weakCanary = canary
            for _ in 0..<3 {
                scheduler.schedule { [canary] in _ = canary } // pending forever
            }
        }
 
        let drained = Locked(false)
        scheduler.cancelAll { drained.mutate { $0 = true } }
        gate.signal()
        #expect(eventually { drained.read { $0 } })
 
        #expect(eventually { weakCanary == nil },
                "cancelled work items still hold their captures — cancellation must release the closures, not just skip execution")
    }
}

