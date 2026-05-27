
//
//  Created by Alejandro on 12/2/25.
//

import Testing
import Foundation
@testable import LearningExercises


@Suite("BuildTracker")
struct BuildTrackerTests {
    
    // MARK: - Helpers
    
    private func collect(_ stream: AsyncStream<BuildStatus>) async -> [BuildStatus] {
        var result: [BuildStatus] = []
        for await status in stream {
            result.append(status)
        }
        return result
    }
    
    private func makeTracker(
        pollInterval: Duration = .milliseconds(200)
    ) -> (MockBuildServer, BuildTracker) {
        let server = MockBuildServer()
        let tracker = BuildTracker(server: server, pollInterval: pollInterval)
        return (server, tracker)
    }
    
    // Helper somewhere in the suite:
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        _ work: @Sendable @escaping () async -> T
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await work() }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return nil
            }
            let result = await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - 1. Happy path
    
    @Test("Successful build emits .running updates and terminates with .succeeded")
    func successfulBuild() async {
        let (server, tracker) = makeTracker()
        let id = UUID()
        await server.registerBuild(id: id, shouldFail: false)
        
        let stream = await tracker.track(buildID: id)
        let statuses = await collect(stream)
        
        #expect(!statuses.isEmpty)
        #expect(statuses.last == .succeeded)
        
        let hasRunning = statuses.contains { status in
            if case .running = status { return true } else { return false }
        }
        #expect(hasRunning, "expected at least one .running update")
    }
    
    // MARK: - 2. Failing build
    
    @Test("Failing build terminates with .failed as the final status")
    func failingBuild() async {
        let (server, tracker) = makeTracker()
        let id = UUID()
        await server.registerBuild(id: id, shouldFail: true)
        
        let stream = await tracker.track(buildID: id)
        let statuses = await collect(stream)
        
        guard case .failed = statuses.last else {
            Issue.record("expected terminal .failed, got \(statuses.last as Any)")
            return
        }
    }
    
    // MARK: - 3. stopTracking
    
    @Test("stopTracking terminates the stream before the build completes")
    func stopTrackingMidFlight() async {
        let (server, tracker) = makeTracker()
        let id = UUID()
        await server.registerBuild(id: id, shouldFail: false)
        
        let consumer = Task { () -> [BuildStatus] in
            let stream = await tracker.track(buildID: id)
            return await self.collect(stream)
        }
        
        try? await Task.sleep(for: .milliseconds(800))
        await tracker.stopTracking(buildID: id)
        
        // Bound the wait so a regression hangs the test rather than the whole suite.
        let statuses = await withTimeout(seconds: 2) {
            await consumer.value
        }
        
        guard let statuses else {
            Issue.record("consumer.value did not return within 2s — stream was not finished")
            return
        }
        
        if let last = statuses.last {
            switch last {
            case .succeeded, .failed:
                Issue.record("stream reached terminal before stopTracking: \(last)")
            default:
                break
            }
        }
        
        let tracked = await tracker.currentlyTracking()
        #expect(!tracked.contains(id))
    }
    
    // MARK: - 4. Multiple builds
    
    @Test("Two builds tracked simultaneously complete independently")
    func multipleBuildsIndependent() async {
        let (server, tracker) = makeTracker()
        let buildA = UUID()
        let buildB = UUID()
        await server.registerBuild(id: buildA, shouldFail: false)
        await server.registerBuild(id: buildB, shouldFail: true)
        
        async let resultA = self.collect(await tracker.track(buildID: buildA))
        async let resultB = self.collect(await tracker.track(buildID: buildB))
        let (a, b) = await (resultA, resultB)
        
        #expect(a.last == .succeeded, "build A should succeed")
        
        guard case .failed = b.last else {
            Issue.record("build B should fail, got \(b.last as Any)")
            return
        }
        
        try? await Task.sleep(for: .milliseconds(100))
        let tracked = await tracker.currentlyTracking()
        #expect(tracked.isEmpty, "no builds should remain tracked")
    }
    
    // MARK: - 5. Unknown build
    
    @Test("Tracking an unknown buildID terminates after 3 consecutive errors")
    func unknownBuildTerminatesAfterThreeErrors() async {
        let (_, tracker) = makeTracker()
        let unknownID = UUID()
        // Intentionally NOT registered. Every poll throws .buildNotFound.
        
        let start = Date()
        let stream = await tracker.track(buildID: unknownID)
        let statuses = await collect(stream)
        let elapsed = Date().timeIntervalSince(start)
        
        #expect(statuses.isEmpty, "no statuses should emit for unknown build")
        #expect(elapsed < 2.0, "stream should terminate promptly")
        
        let tracked = await tracker.currentlyTracking()
        #expect(!tracked.contains(unknownID))
    }
    
    // MARK: - 6. Dedup
    
    @Test("Never emits two consecutive identical statuses")
    func dedupConsecutiveStatuses() async {
        let (server, tracker) = makeTracker(pollInterval: .milliseconds(50))
        let id = UUID()
        await server.registerBuild(id: id, shouldFail: false)
        
        let stream = await tracker.track(buildID: id)
        let statuses = await collect(stream)
        
        for i in 1..<statuses.count {
            #expect(
                statuses[i] != statuses[i - 1],
                "duplicate at index \(i): \(statuses[i])"
            )
        }
    }
    
    // MARK: - 7. currentlyTracking cleanup
    
    @Test("currentlyTracking is cleaned up after the build reaches a terminal status")
    func currentlyTrackingCleansUpAfterTerminal() async {
        let (server, tracker) = makeTracker()
        let id = UUID()
        await server.registerBuild(id: id, shouldFail: false)
        
        let stream = await tracker.track(buildID: id)
        
        let duringPolling = await tracker.currentlyTracking()
        #expect(duringPolling.contains(id), "build should be tracked while polling")
        
        _ = await collect(stream)
        
        try? await Task.sleep(for: .milliseconds(100))
        
        let afterCompletion = await tracker.currentlyTracking()
        #expect(!afterCompletion.contains(id), "build should be removed after terminal")
    }
    
    // MARK: - 8. Consumer cancellation
    
    @Test("Cancelling the consumer task cleans up tracking state")
    func consumerTaskCancelled() async {
        let (server, tracker) = makeTracker()
        let id = UUID()
        await server.registerBuild(id: id, shouldFail: false)
        
        let consumer = Task {
            let stream = await tracker.track(buildID: id)
            var count = 0
            for await _ in stream {
                count += 1
            }
            return count
        }
        
        // Let a couple polls happen so we know the stream is running.
        try? await Task.sleep(for: .milliseconds(500))
        consumer.cancel()
        
        // Wait for the consumer to actually exit, then give the actor a beat
        // to process onTermination's cleanup hop.
        _ = await consumer.value
        try? await Task.sleep(for: .milliseconds(100))
        
        let tracked = await tracker.currentlyTracking()
        #expect(!tracked.contains(id), "build should be removed after consumer cancellation")
    }
}


struct SyncCoordinatorTests {

    @Test func testBasicSync() async {
        print("=== Test 1: Sync 30 notes ===")
        let coordinator = SyncCoordinator(uploadRate: 3, rateLimit: 5)
        let notes = generateNotes(count: 30)
        
        let start = Date()
        let report = await coordinator.sync(notes)
        let elapsed = Date().timeIntervalSince(start)
        
        let total = report.succeeded.count + report.failed.count + report.cancelled.count
        print(String(format: "  Elapsed:     %.2fs", elapsed))
        print("  Succeeded:   \(report.succeeded.count)")
        print("  Failed:      \(report.failed.count)")
        print("  Cancelled:   \(report.cancelled.count)")
        print("  Accounted:   \(total) of \(notes.count)")
        
        // Expected behavior, if the gate works:
        //   - 30 notes / 3 concurrent = 10 sequential "batches"
        //   - Each upload averages ~250ms (latency 100-400ms, uniform)
        //   - ~2.5s total, give or take retries on the ~10% failures
        //   - "Accounted" should equal 30
        //
        // If elapsed is well under 1s, the concurrency cap is a no-op.
        // If "Accounted" is 0, results aren't being collected from the group.
        print()
    }

    @Test func testCancellation() async {
        print("=== Test 2: Cancellation mid-flight ===")
        let coordinator = SyncCoordinator(uploadRate: 3, rateLimit: 5)
        let notes = generateNotes(count: 50)
        
        let start = Date()
        let syncTask = Task { await coordinator.sync(notes) }
        
        // Give the coordinator time to start a few uploads, then yank the cord.
        try? await Task.sleep(for: .milliseconds(300))
        await coordinator.cancelAll()
        
        let report = await syncTask.value
        let elapsed = Date().timeIntervalSince(start)
        let total = report.succeeded.count + report.failed.count + report.cancelled.count
        
        print(String(format: "  Elapsed:     %.2fs", elapsed))
        print("  Succeeded:   \(report.succeeded.count)")
        print("  Failed:      \(report.failed.count)")
        print("  Cancelled:   \(report.cancelled.count)")
        print("  Accounted:   \(total) of \(notes.count)")
        
        // Expected:
        //   - Elapsed should be well under what 50 notes would normally take (~4s)
        //   - cancelled.count should be the bulk of the 50
        //   - A handful that completed before the cancel may be in succeeded
        //   - Accounted should still equal 50 — no notes vanish
        print()
    }

    @Test func testConcurrentSyncCalls() async {
        print("=== Test 3: Two concurrent sync() calls share the gate ===")
        let coordinator = SyncCoordinator(uploadRate: 3, rateLimit: 5)
        let batchA = generateNotes(count: 15)
        let batchB = generateNotes(count: 15)
        
        let start = Date()
        async let reportA = coordinator.sync(batchA)
        async let reportB = coordinator.sync(batchB)
        let (a, b) = await (reportA, reportB)
        let elapsed = Date().timeIntervalSince(start)
        
        print(String(format: "  Elapsed:     %.2fs", elapsed))
        print("  Batch A:     \(a.succeeded.count) ok, \(a.failed.count) failed, \(a.cancelled.count) cancelled")
        print("  Batch B:     \(b.succeeded.count) ok, \(b.failed.count) failed, \(b.cancelled.count) cancelled")
        
        // Expected:
        //   - Two batches of 15 = 30 total notes
        //   - Shared gate at 3 concurrent → same ~2.5s as Test 1
        //   - If elapsed is ~1.25s, the gate is per-call, not per-actor (bug)
        //   - If elapsed is much higher, calls are accidentally serializing somewhere
        print()
    }
    
    func generateNotes(count: Int) -> [Note] {
        (0..<count).map { i in
            Note(
                id: UUID(),
                title: "Note #\(i)",
                body: "Body content for note number \(i). Lorem ipsum filler."
            )
        }
    }
    
}
