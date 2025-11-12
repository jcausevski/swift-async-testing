import Foundation

/// A test context that captures expectations for async sequence testing.
public final class AsyncSequenceTestContext<Element> {
    internal var expectations: [any EmitExpectation] = []

    internal func validate<S: AsyncSequence>(against sequence: S) async throws where S.Element == Element {
        var iterator = sequence.makeAsyncIterator()
        var expectationIndex = 0

        while let element = try await iterator.next() {
            if expectationIndex >= expectations.count {
                throw AsyncTestError.unexpectedElement(String(describing: element))
            }

            let expectation = expectations[expectationIndex]
            if try expectation.matches(element) {
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
