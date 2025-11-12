import Foundation

/// Errors that can occur during async sequence testing.
public enum AsyncTestError: Error, CustomStringConvertible {
    case unexpectedElement(String)
    case expectationMismatch(expected: String, actual: String, at: Int)
    case insufficientElements(expected: Int, actual: Int)

    public var description: String {
        switch self {
        case .unexpectedElement(let element):
            return "Unexpected element received: \(element)"
        case .expectationMismatch(let expected, let actual, let index):
            return "Expectation at index \(index) failed. Expected: \(expected), but got: \(actual)"
        case .insufficientElements(let expected, let actual):
            return "Insufficient elements. Expected \(expected), but got \(actual)"
        }
    }
}
