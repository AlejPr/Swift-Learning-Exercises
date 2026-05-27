//
//  LearningExercisesTests.swift
//  LearningExercisesTests
//
//  Created by Alejandro on 5/26/26.
//

import Foundation
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


struct UserDefaultsTests {
    
    @Test func example() {
        let store: UserDefaultsStore = UserDefaultsStore(standard: UserDefaults.standard)

        let preferences = User.Preferences(isDarkMode: true, notificationsEnabled: false)
        let userId = UUID()
        let currentDate = Date()
        let johnSmith = User(
            id: userId,
            name: "John Smith",
            email: "johnsmith@test.com",
            createdAt: currentDate,
            preferences: preferences
        )

        do {
           try store.save(johnSmith, forKey: "johnSmith")
           print("Saved")
        }
        catch { print(error) }
        
        do {
           let retrieved = try store.load(User.self, forKey: "johnSmith")
           assert(retrieved == johnSmith)
           print("Retrieved")
        }
        catch { print(error) }
        
        store.delete(forKey: "johnSmith")
        assert(store.exists(forKey: "johnSmith") == false)
        print("Passed All Cases")


        @UserDefault("peggySmith", store: store, defaultValue: User.none)
        var maggieSmith: User?

        maggieSmith = User(
            id: UUID(),
            name: "Peggy Smith",
            email: "peggy.smith@test.com",
            createdAt: Date(),
            preferences: User.Preferences(isDarkMode: true, notificationsEnabled: true)
        )

        do {
            let retrieved = try store.load(User.self, forKey: "peggySmith")
            assert(retrieved?.name == "Peggy Smith")
            print("Passed Property Wrapper Bonus")
        } catch { print(error) }
    }
    
}
