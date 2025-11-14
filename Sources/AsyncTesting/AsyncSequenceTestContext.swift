import Foundation
import Testing

/// A test context that captures expectations for async sequence testing.
public final class AsyncSequenceTestContext<Element> {
    internal var expectations: [any AsyncSequenceExpectation] = []

    internal func validate<S: AsyncSequence>(against sequence: S) async throws
    where S.Element == Element {
        var iterator = sequence.makeAsyncIterator()
        var expectationIndex = 0

        while true {
            do {
                guard let element = try await iterator.next() else {
                    if expectationIndex < expectations.count {

                        for i in expectationIndex..<expectations.count {
                            if expectations[i] is ErrorExpectation {
                                throw AsyncTestError.expectedErrorButSequenceSucceeded(
                                    expectedError: expectations[i].description,
                                    at: i,
                                    sourceLocation: expectations[i].sourceLocation
                                )
                            }
                        }
                    }
                    break
                }
                if expectationIndex >= expectations.count {
                    let sourceLocation =
                        expectations.isEmpty ? #_sourceLocation : expectations.last!.sourceLocation
                    throw AsyncTestError.unexpectedElement(
                        element: String(describing: element),
                        at: expectationIndex,
                        sourceLocation: sourceLocation
                    )
                }

                let expectation = expectations[expectationIndex]

                if expectation is ErrorExpectation {
                    throw AsyncTestError.expectedErrorButSequenceSucceeded(
                        expectedError: expectation.description,
                        at: expectationIndex,
                        sourceLocation: expectation.sourceLocation
                    )
                }

                if let skipExpectation = expectation as? SkipCountExpectation {
                    guard skipExpectation.count > 0 else {
                        throw AsyncTestError.invalidSkipCount(
                            count: skipExpectation.count,
                            sourceLocation: skipExpectation.sourceLocation
                        )
                    }

                    var elementsSkipped = 1
                    while elementsSkipped < skipExpectation.count {
                        guard (try await iterator.next()) != nil else {
                            throw AsyncTestError.insufficientElementsForSkip(
                                skipCount: skipExpectation.count,
                                elementsSkipped: elementsSkipped,
                                expectationIndex: expectationIndex,
                                totalExpectations: expectations.count,
                                sourceLocation: skipExpectation.sourceLocation
                            )
                        }
                        elementsSkipped += 1
                    }

                    expectationIndex += 1
                } else if expectation is SkipExpectation {
                    expectationIndex += 1
                } else if expectation is SkipAllExpectation {
                    while (try await iterator.next()) != nil {
                        // Keep consuming until no more elements
                    }
                    expectationIndex += 1
                    break
                } else if expectation is EventuallyExpectation {
                    var found = false
                    var currentElement = element

                    while true {
                        if try expectation.matches(currentElement) {
                            found = true
                            break
                        }

                        guard let nextElement = try await iterator.next() else {
                            throw AsyncTestError.expectationMismatch(
                                expected: "eventually: " + expectation.description,
                                actual: "sequence ended without finding match",
                                at: expectationIndex,
                                sourceLocation: expectation.sourceLocation
                            )
                        }
                        currentElement = nextElement
                    }

                    if found {
                        expectationIndex += 1
                    }
                } else if try expectation.matches(element) {
                    expectationIndex += 1
                } else {
                    throw AsyncTestError.expectationMismatch(
                        expected: expectation.description,
                        actual: String(describing: element),
                        at: expectationIndex,
                        sourceLocation: expectation.sourceLocation
                    )
                }
            } catch let error as AsyncTestError {
                throw error
            } catch {
                if expectationIndex < expectations.count {
                    let expectation = expectations[expectationIndex]

                    if let errorExpectation = expectation as? ErrorExpectation {
                        if errorExpectation.matchesError(error) {
                            return
                        } else {
                            throw AsyncTestError.errorExpectationMismatch(
                                expectedError: expectation.description,
                                actualError: String(describing: error),
                                at: expectationIndex,
                                sourceLocation: expectation.sourceLocation
                            )
                        }
                    } else {
                        throw error
                    }
                } else {
                    throw error
                }
            }
        }

        if expectationIndex < expectations.count {
            let unprocessedExpectations = Array(expectations.dropFirst(expectationIndex))

            if unprocessedExpectations.count == 1
                && unprocessedExpectations.first is SkipAllExpectation
            {
                return
            }

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
