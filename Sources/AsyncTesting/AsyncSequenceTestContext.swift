import Foundation
import Testing

/// A test context that captures expectations for async sequence testing.
public final class AsyncSequenceTestContext<Element> {
    internal var expectations: [any AsyncSequenceExpectation] = []

    internal func validate<S: AsyncSequence>(against sequence: S) async throws where S.Element == Element {
        var iterator = sequence.makeAsyncIterator()
        var expectationIndex = 0

        while let element = try await iterator.next() {
            if expectationIndex >= expectations.count {
                // Use the source location of the last expectation processed (or a default if none)
                let sourceLocation = expectations.isEmpty ? #_sourceLocation : expectations.last!.sourceLocation
                throw AsyncTestError.unexpectedElement(
                    element: String(describing: element),
                    at: expectationIndex,
                    sourceLocation: sourceLocation
                )
            }

            let expectation = expectations[expectationIndex]

            // Handle skip expectations differently
            if let skipExpectation = expectation as? SkipCountExpectation {
                // Validate skip count before processing
                guard skipExpectation.count > 0 else {
                    throw AsyncTestError.invalidSkipCount(
                        count: skipExpectation.count,
                        sourceLocation: skipExpectation.sourceLocation
                    )
                }

                // Skip multiple elements for SkipCountExpectation
                var elementsSkipped = 0
                // First, consume the current element
                elementsSkipped += 1

                // Then consume additional elements if needed
                while elementsSkipped < skipExpectation.count {
                    guard let _ = try await iterator.next() else {
                        throw AsyncTestError.insufficientElementsForSkip(
                            skipCount: skipExpectation.count,
                            elementsSkipped: elementsSkipped,
                            expectationIndex: expectationIndex,
                            totalExpectations: expectations.count
                        )
                    }
                    elementsSkipped += 1
                }

                expectationIndex += 1
            } else if expectation is SkipExpectation {
                // Skip single element for SkipExpectation
                expectationIndex += 1
            } else if expectation is SkipAllExpectation {
                // Skip all remaining elements for SkipAllExpectation
                // Consume all remaining elements from the iterator and finish
                while let _ = try await iterator.next() {
                    // Keep consuming until no more elements
                }
                expectationIndex += 1
                break // Exit the while loop since we've consumed all elements
            } else if try expectation.matches(element) {
                // Regular expectation matching
                expectationIndex += 1
            } else {
                throw AsyncTestError.expectationMismatch(
                    expected: expectation.description,
                    actual: String(describing: element),
                    at: expectationIndex,
                    sourceLocation: expectation.sourceLocation
                )
            }
        }

        if expectationIndex < expectations.count {
            let unprocessedExpectations = Array(expectations.dropFirst(expectationIndex))

            // Special case: if the only remaining expectation is skipAll, it's considered successful
            if unprocessedExpectations.count == 1 && unprocessedExpectations.first is SkipAllExpectation {
                // skipAll can succeed even when no elements remain
                return
            }

            // Get the source location of the first unprocessed expectation for better error reporting
            let sourceLocation = expectations[expectationIndex].sourceLocation
            throw AsyncTestError.insufficientElements(
                expected: expectations.count,
                actual: expectationIndex,
                unprocessedExpectations: unprocessedExpectations.map({ $0.description }),
                sourceLocation: sourceLocation
            )
        }
    }
}
