//
//  LearningExercisesTests.swift
//  LearningExercisesTests
//
//  Created by Alejandro on 5/26/26.
//

import Testing
@testable import LearningExercises

struct LearningExercisesTests {

    actor Log {
        private var lines: [String] = []
        func append(_ line: String) { lines.append(line) }
        func print() { for line in lines { Swift.print(line) } }
    }
    
    @Test func MutexTest() async throws {
        let mutex = AsyncMutex()
        let log = Log()  // a simple actor-wrapped [String] for ordering

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let key = await mutex.lock()
                    await log.append("task \(i) acquired")
                    try? await Task.sleep(for: .milliseconds(100))
                    await log.append("task \(i) releasing")
                    try? await mutex.unlock(key)
                }
            }
        }
        await log.print()
    }

    @Test func SemaphoreTest() async throws {
        let sem = AsyncSemaphore(limit: 5)
        let log = Log()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await sem.acquireSlot()
                    await log.append("task \(i) in")
                    try? await Task.sleep(for: .milliseconds(200))
                    await log.append("task \(i) out")
                    await sem.releaseSlot()
                }
            }
        }
        await log.print()
    }
    
    
    @Test func RateLimiterTest() async throws {
        let limiter = RateLimiter(maxOperations: 2, per: .seconds(3))
        let log = Log()
        let start = ContinuousClock.now

        for i in 0..<10 {
            await limiter.acquire()
            let elapsed = ContinuousClock.now - start
            await log.append("op \(i) at \(elapsed)")
        }
        await log.print()
    }
    
    
}
