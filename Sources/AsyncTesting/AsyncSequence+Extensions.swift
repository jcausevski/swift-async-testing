import Foundation
import Testing

extension AsyncSequence {
    /// Creates a test for this async sequence that throws on mismatched expectations.
    /// - Parameter expectations: A result builder closure that defines the expected expectations.
    public func testThrowing(@AsyncSequenceExpectationBuilder<Element> _ expectations: () -> [AsyncSequenceExpectation]) async throws {
        let context = AsyncSequenceTestContext<Element>()
        context.expectations = expectations()
        try await context.validate(against: self)
    }

    /// Creates a test for this async sequence that records issues using Swift Testing instead of throwing errors.
    /// - Parameter expectations: A result builder closure that defines the expected expectations.
    public func test(@AsyncSequenceExpectationBuilder<Element> _ expectations: () -> [AsyncSequenceExpectation]) async {
        let context = AsyncSequenceTestContext<Element>()
        context.expectations = expectations()

        do {
            try await context.validate(against: self)
        } catch let error as AsyncTestError {
            switch error {
            case .unexpectedElement(let element, let expectationIndex, let sourceLocation):
                Issue.record(
                    """
                    Unexpected element received at position \(expectationIndex)

                    Expected no more elements, but received: \(element)

                    This indicates that the async sequence produced more elements than were expected in the test definition.
                    """,
                    sourceLocation: sourceLocation
                )

            case .expectationMismatch(let expected, let actual, let expectationIndex, let sourceLocation):
                Issue.record(
                    """
                    Expectation mismatch at index \(expectationIndex)

                    Expected: \(expected)
                    Received: \(actual)

                    This indicates that the async sequence element does not match the expected value or predicate.
                    Check your test expectations to ensure they match the actual sequence behavior.
                    """,
                    sourceLocation: sourceLocation
                )

            case .insufficientElements(let expected, let actual, let unprocessedExpectations, let sourceLocation):
                Issue.record(
                    """
                    Insufficient elements in async sequence

                    Expected \(expected) elements, but only received \(actual).

                    Unprocessed expectations:
                    \(unprocessedExpectations.map { "- \($0)" }.joined(separator: "\n"))

                    This indicates that the async sequence ended before all expected elements were received.
                    Verify that your async sequence produces the expected number of elements.
                    """,
                    sourceLocation: sourceLocation
                )

            case .insufficientElementsForSkip(let skipCount, let elementsSkipped, let expectationIndex, let totalExpectations, let sourceLocation):
                Issue.record(
                    """
                    Insufficient elements for skip operation

                    Attempted to skip \(skipCount) elements, but only \(elementsSkipped) elements were available.

                    Current expectation index: \(expectationIndex)
                    Total expectations: \(totalExpectations)
                    Elements processed: \(elementsSkipped)

                    This error occurs when the async sequence ends before all skip operations can be completed.
                    """,
                    sourceLocation: sourceLocation
                )

            case .invalidSkipCount(let skipCount, let sourceLocation):
                Issue.record(
                    """
                    Invalid skip count: \(skipCount)

                    Skip count must be greater than 0. Provided count: \(skipCount)

                    Use skip() for single element skipping or skip(n) where n > 0 for multiple elements.
                    """,
                    sourceLocation: sourceLocation
                )

            case .expectedErrorButSequenceSucceeded(let expectedError, let expectationIndex, let sourceLocation):
                Issue.record(
                    """
                    Expected error at position \(expectationIndex), but sequence succeeded

                    Expected: \(expectedError)

                    This indicates that the async sequence finished without throwing an error when an error was expected.
                    Verify that your async sequence should throw an error or remove the error expectation.
                    """,
                    sourceLocation: sourceLocation
                )

            case .errorExpectationMismatch(let expectedError, let actualError, let expectationIndex, let sourceLocation):
                Issue.record(
                    """
                    Error expectation mismatch at index \(expectationIndex)

                    Expected error: \(expectedError)
                    Actual error: \(actualError)

                    This indicates that the async sequence threw an error, but it doesn't match the expected error criteria.
                    Check your error expectations to ensure they match the actual error behavior.
                    """,
                    sourceLocation: sourceLocation
                )
            }
        } catch {
            Issue.record(
                """
                An unexpected error occurred during async sequence testing: \(error)
                """
            )
        }
    }
}
