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


@Suite("TTLCache")
struct TTLCacheTests {
    
    actor CallCounter {
        private(set) var count = 0
        func increment() { count += 1 }
    }
    
    @Test func BasicTests() async {
        let clock = ContinuousClock()
        let cache = TTLCache<String, Int>(defaultTTL: .seconds(1), clock: clock)
        
        //Test setting values works
        for i in 1...10 {
            await cache.set(i, for: String(i))
        }
        var storedCount = await cache.count()
        assert(storedCount == 10)
        print("10 keys counted")
        
        //test cleanup
        for i in 11...12 {
            await cache.set(i, for: String(i), ttl: .seconds(5))
        }
        try? await Task.sleep(for: .seconds(2))
        storedCount = await cache.count()
        assert(storedCount == 2)
        print("2 keys remaining after cleanup")
        
        //test invalidation
        await cache.invalidate(key: String(11))
        storedCount = await cache.count()
        assert(storedCount == 1)
        print("1 key remaining after invalidation of key 11")
        
        for i in 1...10 {
            await cache.set(i, for: String(i))
        }
        await cache.invalidateAll()
        storedCount = await cache.count()
        assert(storedCount == 0)
        print("all keys successfully invalidated")
        
    }
    
    @Test func AdvancedTests() async {
        let clock = ContinuousClock()
        let start = Date()
        let cache = TTLCache<String, Int>(defaultTTL: .seconds(1), clock: clock)

        
        //Loader Test
        do {
            let value = try await cache.value(for: "testValue") {
                try await Task.sleep(for: .seconds(2))
                return 2
            }
            assert(value == 2)
            print("Loading value works and returns correct value.")
        } catch { assertionFailure(error.localizedDescription) }
        
        
        //Set while loading test
        print("retrieving value with loader at \(Date().timeIntervalSince(start))")
        let value = Task {
            try await cache.value(for: "testValue") {
                try await Task.sleep(for: .seconds(2))
                print("loader finished sleeping at \(Date().timeIntervalSince(start))")
                return 2
            }
        }
        
        print("setting value at \(Date().timeIntervalSince(start))")
        await cache.set(1, for: "testValue")
        
        let result = await value.result
        print("value returned at \(Date().timeIntervalSince(start)) is \(result)")
        switch result {
        case .success(let val):
            assert(val == 1)
            print("TLLCache returned correct value of 1 after setting during loading")
        case .failure(let err): assertionFailure(err.localizedDescription)
        }
            
        
        //Canceling while loading test
        
    }

    @Test func coalescing() async throws {
        let cache = TTLCache<String, Int>(defaultTTL: .seconds(5))
        let counter = CallCounter()

        // Start 10 concurrent requests for the SAME missing key.
        // .map creates all tasks up front — none are awaited yet, so they
        // genuinely run concurrently.
        let tasks = (0..<10).map { _ in
            Task {
                try await cache.value(for: "shared") {
                    await counter.increment()
                    try await Task.sleep(for: .milliseconds(200))  // widen the in-flight window
                    return 42
                }
            }
        }

        // Now await all of them.
        var results: [Int] = []
        for task in tasks {
            results.append(try await task.value)
        }

        // Every caller received the same value.
        #expect(results.allSatisfy { $0 == 42 })

        // The loader ran exactly once — this is the actual coalescing assertion.
        let callCount = await counter.count
        #expect(callCount == 1, "loader ran \(callCount) times, expected 1")
    }
    
}
