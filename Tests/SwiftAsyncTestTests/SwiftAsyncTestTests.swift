import Testing
import Foundation
@testable import SwiftAsyncTest

final class AsyncSequenceTests {

    @Test("Test basic string emits")
    func testBasicStringEmits() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        try await sequence.test { context in
            context.emit("hello")
            context.emit("world")
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

        try await sequence.test { context in
            context.emit(where: { $0 > 5 })
            context.emit(where: { $0 % 20 == 0 })
            context.emit(where: { $0 == 30 })
        }
    }

    @Test("Test AsyncThrowingStream")
    func testAsyncThrowingStream() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("value1")
            continuation.yield("value2")
            continuation.finish()
        }

        try await sequence.test { context in
            context.emit("value1")
            context.emit("value2")
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
            try await sequence.test { context in
                context.emit("hello")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch TestError.unexpectedElement(let element) {
            #expect(element == "unexpected")
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
            try await sequence.test { context in
                context.emit("hello")
                context.emit("world")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch TestError.insufficientElements(let expected, let actual) {
            #expect(expected == 2)
            #expect(actual == 1)
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
            try await sequence.test { context in
                context.emit("hello")
                context.emit("world")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch TestError.expectationMismatch(let expected, let actual, let index) {
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
            try await sequence.test { context in
                context.emit("hello")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch TestError.insufficientElements(let expected, let actual) {
            #expect(expected == 1)
            #expect(actual == 0)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
