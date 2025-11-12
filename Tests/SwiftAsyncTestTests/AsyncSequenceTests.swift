import Testing
import Foundation
@testable import SwiftAsyncTest

final class AsyncSequenceTests {

    @Test("Test equatable emits")
    func testEquatableEmits() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        await sequence.test {
            emit("hello")
            emit("world")
        }
    }

    @Test("Test emits with predicate matching")
    func testPredicateMatching() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.yield(30)
            continuation.finish()
        }

        await sequence.test {
            emit(where: { $0 > 5 })
            emit(where: { $0 % 20 == 0 })
            emit(where: { $0 == 30 })
        }
    }

    // MARK: - Error Cases

    @Test("Test unexpected element error")
    func testUnexpectedElementError() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("unexpected")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.unexpectedElement(let element, let at, _) {
            #expect(element == "unexpected")
            #expect(at == 1)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test insufficient elements error")
    func testInsufficientElementsError() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
                emit("world")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.insufficientElements(let expected, let actual, let unprocessedExpectations, _) {
            #expect(expected == 2)
            #expect(actual == 1)
            #expect(unprocessedExpectations.count == 1)
            #expect(unprocessedExpectations.first == "world")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test expectation mismatch error")
    func testExpectationMismatchError() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("wrong")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
                emit("world")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.expectationMismatch(let expected, let actual, let index, _) {
            #expect(index == 1)
            #expect(expected == "world")
            #expect(actual == "wrong")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test empty sequence with expectations")
    func testEmptySequenceWithExpectations() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.insufficientElements(let expected, let actual, let unprocessedExpectations, _) {
            #expect(expected == 1)
            #expect(actual == 0)
            #expect(unprocessedExpectations.count == 1)
            #expect(unprocessedExpectations.first == "hello")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    // MARK: - Skip Tests

    @Test("Test skipping single element")
    func testSkipSingleElement() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("skip_me")
            continuation.yield("world")
            continuation.finish()
        }

        await sequence.test {
            emit("hello")
            skip()
            emit("world")
        }
    }

    @Test("Test skipping multiple elements with count")
    func testSkipMultipleElements() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.yield(4)
            continuation.yield(5)
            continuation.finish()
        }

        await sequence.test {
            emit(1)
            skip(2) // Skip elements 2 and 3
            emit(4)
            emit(5)
        }
    }

    @Test("Test multiple skips in sequence")
    func testMultipleSkips() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("keep1")
            continuation.yield("skip1")
            continuation.yield("keep2")
            continuation.yield("skip2")
            continuation.yield("skip3")
            continuation.yield("keep3")
            continuation.finish()
        }

        await sequence.test {
            emit("keep1")
            skip()
            emit("keep2")
            skip(2)
            emit("keep3")
        }
    }

    // MARK: - Skip Error Cases

    @Test("Test insufficient elements for skip")
    func testInsufficientElementsForSkip() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
                skip(2) // Tries to skip 2 elements but only 1 remains
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.insufficientElementsForSkip(let skipCount, let elementsSkipped, let expectationIndex, let totalExpectations) {
            #expect(skipCount == 2)
            #expect(elementsSkipped == 1)
            #expect(expectationIndex == 1)
            #expect(totalExpectations == 2)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test skip with negative count")
    func testSkipWithNegativeCount() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
                skip(-5) // Should throw an error for negative count
            }
            #expect(Bool(false), "Expected test to throw an error for negative skip count")
        } catch AsyncTestError.invalidSkipCount(let count, _) {
            #expect(count == -5, "Expected error to contain the invalid skip count")
        }
    }

    @Test("Test skip zero elements")
    func testSkipZeroElements() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("hello")
                skip(0) // Should throw an error for zero count
            }
            #expect(Bool(false), "Expected test to throw an error for zero skip count")
        } catch AsyncTestError.invalidSkipCount(let count, _) {
            #expect(count == 0, "Expected error to contain the invalid skip count")
        }
    }
}
