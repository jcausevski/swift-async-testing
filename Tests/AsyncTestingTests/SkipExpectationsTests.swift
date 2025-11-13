import Foundation
import Testing

@testable import AsyncTesting

final class SkipExpectationsTests {

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
            skip(2)
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
                skip(2)
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.insufficientElementsForSkip(
            let skipCount,
            let elementsSkipped,
            let expectationIndex,
            let totalExpectations
        ) {
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
                skip(-5)
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
                skip(0)
            }
            #expect(Bool(false), "Expected test to throw an error for zero skip count")
        } catch AsyncTestError.invalidSkipCount(let count, _) {
            #expect(count == 0, "Expected error to contain the invalid skip count")
        }
    }

    @Test("Test skip all remaining elements")
    func testSkipAllRemainingElements() async throws {
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
            emit(2)
            skipAll()
        }
    }

    @Test("Test skip all with no remaining elements")
    func testSkipAllWithNoRemainingElements() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        await sequence.test {
            emit("hello")
            emit("world")
            skipAll()
        }
    }

    @Test("Test skip all as first expectation")
    func testSkipAllAsFirstExpectation() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("ignore1")
            continuation.yield("ignore2")
            continuation.yield("ignore3")
            continuation.finish()
        }

        await sequence.test {
            skipAll()
        }
    }

    @Test("Test skip all followed by more expectations should fail")
    func testSkipAllFollowedByMoreExpectations() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit(1)
                skipAll()
                emit(4)
            }
            #expect(Bool(false), "Expected test to throw an error for expectations after skipAll")
        } catch AsyncTestError.insufficientElements(
            let expected, let actual, let unprocessedExpectations, _)
        {
            #expect(expected == 3)
            #expect(actual == 2)
            #expect(unprocessedExpectations.count == 1)
            #expect(unprocessedExpectations.first == "4")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
