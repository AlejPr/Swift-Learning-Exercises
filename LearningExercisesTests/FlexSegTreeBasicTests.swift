

import Foundation
import Testing
@testable import LearningExercises

@Suite("FlexSegTree basic behavior")
struct FlexSegTreeBasicTests {

    @Test("Sum tree: single point updates and full range query")
    func sumTreeBasic() async throws {
        for _ in 0...0 {
            print("called")
        }
        // Identity for sum is 0
        var seg = FlexSegTree<Int>(8, 0, operation: +)
        // Initially all zeros
        #expect(seg.query(0, 7) == 0)

        // Point updates
        seg.update(0, 3)
        seg.update(3, 5)
        seg.update(7, 2)

        // Queries
        #expect(seg.query(0, 0) == 3)
        #expect(seg.query(3, 3) == 5)
        #expect(seg.query(7, 7) == 2)
        #expect(seg.query(0, 3) == 8)
        #expect(seg.query(4, 7) == 2)
        #expect(seg.query(0, 7) == 10)

        // Update overwrite
        seg.update(3, 1)
        #expect(seg.query(0, 7) == 6)
        #expect(seg.query(2, 5) == 1)
    }

    @Test("Min tree: identity and range mins")
    func minTreeQueries() async throws {
        // Identity for min is Int.max
        var seg = FlexSegTree<Int>(6, Int.max, operation: { min($0, $1) })

        // Set values
        seg.update(0, 5)
        seg.update(1, 3)
        seg.update(2, 7)
        seg.update(3, 2)
        seg.update(4, 9)
        seg.update(5, 6)

        #expect(seg.query(0, 5) == 2)
        #expect(seg.query(0, 1) == 3)
        #expect(seg.query(1, 3) == 2)
        #expect(seg.query(2, 4) == 2)
        #expect(seg.query(4, 5) == 6)

        // Update to raise/lower mins
        seg.update(3, 8)
        #expect(seg.query(0, 5) == 3)
        seg.update(1, 10)
        #expect(seg.query(0, 2) == 5)
    }

    @Test("Max tree: inclusive range behavior")
    func maxTreeInclusiveRanges() async throws {
        // Identity for max is Int.min
        var seg = FlexSegTree<Int>(5, Int.min, operation: { max($0, $1) })

        seg.update(0, 1)
        seg.update(1, 4)
        seg.update(2, 3)
        seg.update(3, 9)
        seg.update(4, 7)

        // Inclusive queries
        #expect(seg.query(0, 0) == 1)
        #expect(seg.query(1, 1) == 4)
        #expect(seg.query(0, 1) == 4)
        #expect(seg.query(1, 2) == 4)
        #expect(seg.query(2, 4) == 9)
        #expect(seg.query(0, 4) == 9)

        // Update and re-check
        seg.update(3, 6)
        #expect(seg.query(2, 4) == 7)
    }
}

@Suite("FlexSegTree edge cases")
struct FlexSegTreeEdgeCases {

    @Test("All identities remain identities")
    func allIdentity() async throws {
        var seg = FlexSegTree<Int>(4, 0, operation: +)
        #expect(seg.query(0, 3) == 0)
        #expect(seg.query(1, 2) == 0)

        seg.update(2, 0)
        #expect(seg.query(2, 2) == 0)
    }

    @Test("Single element tree")
    func singleElement() async throws {
        var segMin = FlexSegTree<Int>(1, Int.max, operation: { min($0, $1) })
        #expect(segMin.query(0, 0) == Int.max)
        segMin.update(0, 42)
        #expect(segMin.query(0, 0) == 42)

        var segSum = FlexSegTree<Int>(1, 0, operation: +)
        #expect(segSum.query(0, 0) == 0)
        segSum.update(0, 5)
        #expect(segSum.query(0, 0) == 5)
    }
}
