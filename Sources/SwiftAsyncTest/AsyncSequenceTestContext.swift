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
                throw AsyncTestError.unexpectedElement(element: String(describing: element), at: expectationIndex, sourceLocation: sourceLocation)
            }

            let expectation = expectations[expectationIndex]

            // Handle skip expectations differently
            if let skipExpectation = expectation as? SkipCountExpectation {
                // Validate skip count before processing
                guard skipExpectation.count > 0 else {
                    throw AsyncTestError.invalidSkipCount(count: skipExpectation.count, sourceLocation: skipExpectation.sourceLocation)
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
            let unprocessedExpectations = Array(expectations.dropFirst(expectationIndex)).map { $0.description }
            // Get the source location of the first unprocessed expectation for better error reporting
            let sourceLocation = expectations[expectationIndex].sourceLocation
            throw AsyncTestError.insufficientElements(
                expected: expectations.count,
                actual: expectationIndex,
                unprocessedExpectations: unprocessedExpectations,
                sourceLocation: sourceLocation
            )
        }
    }
}
