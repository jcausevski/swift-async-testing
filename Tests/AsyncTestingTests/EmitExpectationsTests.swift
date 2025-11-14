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

    @Test("Test emitEventually with equatable values")
    func testEmitEventuallyEquatable() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("ignore")
            continuation.yield("hello")
            continuation.yield("ignore")
            continuation.yield("world")
            continuation.finish()
        }

        await sequence.test {
            emitEventually("hello")
            emitEventually("world")
        }
    }

    @Test("Test emitEventually with predicate")
    func testEmitEventuallyPredicate() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(5)
            continuation.yield(10)
            continuation.yield(20)
            continuation.yield(15)
            continuation.finish()
        }

        await sequence.test {
            emitEventually(where: { $0 > 8 })
            skipAll()
        }
    }

    @Test("Test emitEventually not found")
    func testEmitEventuallyNotFound() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("hello")
            continuation.yield("world")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emitEventually("missing")
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.expectationMismatch(let expected, let actual, let index, _) {
            #expect(index == 0)
            #expect(expected.contains("eventually:"))
            #expect(expected.contains("missing"))
            #expect(actual.contains("sequence ended without finding match"))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test emitEventually combined with regular emit")
    func testEmitEventuallyWithRegularEmit() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("start")
            continuation.yield("ignore")
            continuation.yield("middle")
            continuation.yield("end")
            continuation.finish()
        }

        await sequence.test {
            emit("start")
            emitEventually("middle")
            emit("end")
        }
    }

    @Test("Test emitEventually with skip")
    func testEmitEventuallyWithSkip() async throws {
        let sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.yield(10)
            continuation.yield(20)
            continuation.yield(30)
            continuation.finish()
        }

        await sequence.test {
            emitEventually(10)
            skip()
            emitEventually(30)
        }
    }
}
