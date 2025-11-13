import Foundation
import Testing

@testable import AsyncTesting

final class AsyncSequenceTests {

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
        } catch AsyncTestError.insufficientElements(
            let expected, let actual, let unprocessedExpectations, _)
        {
            #expect(expected == 2)
            #expect(actual == 1)
            #expect(unprocessedExpectations.count == 1)
            #expect(unprocessedExpectations.first == "world")
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
        } catch AsyncTestError.insufficientElements(
            let expected, let actual, let unprocessedExpectations, _)
        {
            #expect(expected == 1)
            #expect(actual == 0)
            #expect(unprocessedExpectations.count == 1)
            #expect(unprocessedExpectations.first == "hello")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
