import Foundation
import Testing

/// A protocol for expectations about async sequence elements.
public protocol AsyncSequenceExpectation {
    func matches(_ element: Any) throws -> Bool
    var description: String { get }
    var sourceLocation: SourceLocation { get }
}

/// A protocol marker for error expectations
public protocol ErrorExpectation: AsyncSequenceExpectation {
    func matchesError(_ error: Error) -> Bool
}
