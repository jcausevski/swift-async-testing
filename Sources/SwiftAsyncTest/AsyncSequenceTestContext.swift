import Foundation

/// A test context that captures expectations for async sequence testing.
public final class AsyncSequenceTestContext<Element> {
    internal var expectations: [any AsyncSequenceExpectation] = []

    internal func validate<S: AsyncSequence>(against sequence: S) async throws where S.Element == Element {
        var iterator = sequence.makeAsyncIterator()
        var expectationIndex = 0

        while let element = try await iterator.next() {
            if expectationIndex >= expectations.count {
                throw AsyncTestError.unexpectedElement(String(describing: element))
            }

            let expectation = expectations[expectationIndex]

            // Handle skip expectations differently
            if let skipExpectation = expectation as? SkipCountExpectation {
                // Skip multiple elements for SkipCountExpectation
                var elementsSkipped = 0
                // First, consume the current element
                elementsSkipped += 1

                // Then consume additional elements if needed
                while elementsSkipped < skipExpectation.count {
                    guard let _ = try await iterator.next() else {
                        throw AsyncTestError.insufficientElements(
                            expected: expectations.count,
                            actual: expectationIndex
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
                    at: expectationIndex
                )
            }
        }

        if expectationIndex < expectations.count {
            throw AsyncTestError.insufficientElements(
                expected: expectations.count,
                actual: expectationIndex
            )
        }
    }
}
