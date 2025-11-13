import Foundation
import Testing

@testable import AsyncTesting

final class EmitExpectationsTests {

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
}
