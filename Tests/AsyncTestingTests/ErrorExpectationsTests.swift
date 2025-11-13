import Foundation
import Testing

@testable import AsyncTesting

final class ErrorExpectationsTests {

    enum TestError: Error, LocalizedError {
        case testError(String)
        case anotherError

        var errorDescription: String? {
            switch self {
            case .testError(let message):
                return "Test error: \(message)"
            case .anotherError:
                return "Another error"
            }
        }
    }

    enum DifferentError: Error, LocalizedError {
        case differentError(String)
    }

    @Test("Test throwing expectError with any error")
    func testExpectErrorAnyErrorThrowing() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.testError("Something went wrong"))
        }

        try await sequence.testThrowing {
            expectError()
        }
    }

    @Test("Test non-throwing expectError with any error")
    func testExpectErrorAnyErrorNonThrowing() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.anotherError)
        }

        await sequence.test {
            expectError()
        }
    }

    @Test("Test expectError when sequence succeeds unexpectedly")
    func testExpectErrorAnyErrorWhenSequenceSucceeds() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("success")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                expectError()
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.expectedErrorButSequenceSucceeded(
            expectedError: _, at: let at, sourceLocation: _)
        {
            #expect(at == 0)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test expectError with matching type")
    func testExpectErrorSpecificType() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.testError("Specific error"))
        }

        try await sequence.testThrowing {
            expectError(TestError.self)
        }
    }

    @Test("Test expectError with non-matching type")
    func testExpectErrorSpecificTypeMismatch() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.testError("Wrong type"))
        }

        do {
            try await sequence.testThrowing {
                expectError(DifferentError.self)
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.errorExpectationMismatch(
            expectedError: _,
            actualError: _,
            at: let at,
            sourceLocation: _
        ) {
            #expect(at == 0)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test expectError when sequence succeeds")
    func testExpectErrorSpecificTypeWhenSequenceSucceeds() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("success")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                expectError(TestError.self)
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.expectedErrorButSequenceSucceeded(
            expectedError: _, at: let at, sourceLocation: _)
        {
            #expect(at == 0)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test expectError with matching predicate")
    func testExpectErrorWithMatchingPredicate() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.testError("Special error"))
        }

        try await sequence.testThrowing {
            expectError { error in
                if let testError = error as? TestError,
                    case .testError(let message) = testError
                {
                    return message.contains("Special")
                }
                return false
            }
        }
    }

    @Test("Test expectError with non-matching predicate")
    func testExpectErrorWithNonMatchingPredicate() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.testError("Different error"))
        }

        do {
            try await sequence.testThrowing {
                expectError { error in
                    if let testError = error as? TestError,
                        case .testError(let message) = testError
                    {
                        return message.contains("Special")
                    }
                    return false
                }
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.errorExpectationMismatch(
            expectedError: _,
            actualError: _,
            at: let at,
            sourceLocation: _
        ) {
            #expect(at == 0)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test expectError when sequence succeeds")
    func testExpectErrorWithPredicateWhenSequenceSucceeds() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("success")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                expectError { _ in true }
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.expectedErrorButSequenceSucceeded(
            expectedError: _, at: let at, sourceLocation: _)
        {
            #expect(at == 0)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Test elements then error should succeed")
    func testExpectationsElementsThenError() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.yield("first")
            continuation.yield("second")
            continuation.finish(throwing: TestError.testError("End error"))
        }

        try await sequence.testThrowing {
            emit("first")
            emit("second")
            expectError(TestError.self)
        }
    }

    @Test("Test error then elements should succeed")
    func testErrorThenElementsShouldSucceed() async throws {
        let sequence = AsyncThrowingStream<String, Error> { continuation in
            continuation.finish(throwing: TestError.testError("Immediate error"))
        }

        try await sequence.testThrowing {
            expectError(TestError.self)
            emit("This should not be processed")
        }
    }

    @Test("Test error expectation after sequence finishes without error")
    func testErrorExpectationAfterSequenceFinished() async throws {
        let sequence = AsyncStream<String> { continuation in
            continuation.yield("only")
            continuation.finish()
        }

        do {
            try await sequence.testThrowing {
                emit("only")
                expectError()
            }
            #expect(Bool(false), "Expected test to throw an error")
        } catch AsyncTestError.expectedErrorButSequenceSucceeded(
            expectedError: _, at: let at, sourceLocation: _)
        {
            #expect(at == 1)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
