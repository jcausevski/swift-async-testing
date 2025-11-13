import Foundation
import Testing

/// Errors that can occur during async sequence testing.
public enum AsyncTestError: Error, CustomStringConvertible {
    case unexpectedElement(element: String, at: Int, sourceLocation: SourceLocation)
    case expectationMismatch(expected: String, actual: String, at: Int, sourceLocation: SourceLocation)
    case insufficientElements(expected: Int, actual: Int, unprocessedExpectations: [String], sourceLocation: SourceLocation)
    case insufficientElementsForSkip(skipCount: Int, elementsSkipped: Int, expectationIndex: Int, totalExpectations: Int)
    case invalidSkipCount(count: Int, sourceLocation: SourceLocation)
    case expectedErrorButSequenceSucceeded(expectedError: String, at: Int, sourceLocation: SourceLocation)
    case errorExpectationMismatch(expectedError: String, actualError: String, at: Int, sourceLocation: SourceLocation)

    public var description: String {
        switch self {
        case .unexpectedElement(let element, _, _):
            return "Unexpected element received: \(element)"
        case .expectationMismatch(let expected, let actual, let index, _):
            return "Expectation at index \(index) failed. Expected: \(expected), but got: \(actual)"
        case .insufficientElements(let expected, let actual, _, _):
            return "Insufficient elements. Expected \(expected), but got \(actual)"
        case .insufficientElementsForSkip(let skipCount, let elementsSkipped, _, _):
            return "Attempted to skip \(skipCount) elements, but only \(elementsSkipped) elements were available."
        case .invalidSkipCount(let count, _):
            return "Invalid skip count: \(count). Skip count must be greater than 0."
        case .expectedErrorButSequenceSucceeded(let expectedError, _, _):
            return "Expected an error (\(expectedError)) but sequence succeeded without throwing"
        case .errorExpectationMismatch(let expectedError, let actualError, _, _):
            return "Error expectation failed. Expected: \(expectedError), but got: \(actualError)"
        }
    }
}
