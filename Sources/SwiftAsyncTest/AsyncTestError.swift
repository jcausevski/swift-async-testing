import Foundation

/// Errors that can occur during async sequence testing.
public enum AsyncTestError: Error, CustomStringConvertible {
    case unexpectedElement(String)
    case expectationMismatch(expected: String, actual: String, at: Int)
    case insufficientElements(expected: Int, actual: Int)
    case invalidSkipCount(count: Int)

    public var description: String {
        switch self {
        case .unexpectedElement(let element):
            return "Unexpected element received: \(element)"
        case .expectationMismatch(let expected, let actual, let index):
            return "Expectation at index \(index) failed. Expected: \(expected), but got: \(actual)"
        case .insufficientElements(let expected, let actual):
            return "Insufficient elements. Expected \(expected), but got \(actual)"
        case .invalidSkipCount(let count):
            return "Invalid skip count: \(count). Skip count must be greater than 0."
        }
    }
}
