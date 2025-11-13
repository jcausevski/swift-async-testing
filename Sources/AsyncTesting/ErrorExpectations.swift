import Foundation
import Testing

/// An expectation that matches any error.
public struct AnyErrorExpectation: ErrorExpectation {
    public let description: String
    public let sourceLocation: SourceLocation

    public init(sourceLocation: SourceLocation = #_sourceLocation) {
        self.description = "any error"
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        return false
    }

    public func matchesError(_ error: Error) -> Bool {
        return true
    }
}

/// An expectation that matches a specific error type.
public struct ErrorTypeExpectation<E: Error>: ErrorExpectation {
    public let expectedErrorType: E.Type
    public let description: String
    public let sourceLocation: SourceLocation

    public init(_ errorType: E.Type, sourceLocation: SourceLocation = #_sourceLocation) {
        self.expectedErrorType = errorType
        self.description = "error of type \(String(describing: errorType))"
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        return false
    }

    public func matchesError(_ error: Error) -> Bool {
        return error is E
    }
}

/// An expectation that matches errors based on a predicate.
public struct ErrorPredicateExpectation: ErrorExpectation {
    public let predicate: @Sendable (Error) -> Bool
    public let description: String
    public let sourceLocation: SourceLocation

    public init(
        where predicate: @escaping @Sendable (Error) -> Bool,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        self.predicate = predicate
        self.description = "error matching predicate"
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        return false
    }

    public func matchesError(_ error: Error) -> Bool {
        return predicate(error)
    }
}
