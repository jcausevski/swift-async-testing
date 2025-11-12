import Foundation
import Testing

/// A protocol for expectations about async sequence elements.
public protocol AsyncSequenceExpectation {
    func matches(_ element: Any) throws -> Bool
    var description: String { get }
    var sourceLocation: SourceLocation { get }
}

// MARK: - Emit Expectation Types

/// An expectation matches a single element from the async sequence.
public struct EquatableValueExpectation<E: Equatable>: AsyncSequenceExpectation {
    public let value: E
    public let description: String
    public let sourceLocation: SourceLocation

    init(value: E, sourceLocation: SourceLocation = #_sourceLocation) {
        self.value = value
        self.description = String(describing: value)
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        guard let typedElement = element as? E else {
            return false
        }
        return typedElement == value
    }
}

/// An expectation matches a predicate for the async sequence.
public struct PredicateExpectation<Element>: AsyncSequenceExpectation {
    public let predicate: @Sendable (Element) -> Bool
    public let description: String
    public let sourceLocation: SourceLocation

    init(predicate: @escaping @Sendable (Element) -> Bool, sourceLocation: SourceLocation = #_sourceLocation) {
        self.predicate = predicate
        self.description = "matching predicate"
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        guard let typedElement = element as? Element else {
            return false
        }
        return predicate(typedElement)
    }
}

// MARK: - Skip Expectations

/// An expectation that skips a single element from the async sequence.
public struct SkipExpectation: AsyncSequenceExpectation {
    public let description: String = "skip element"
    public let sourceLocation: SourceLocation

    public init(sourceLocation: SourceLocation = #_sourceLocation) {
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        // Skip expectations always match any element since they're designed to skip
        return true
    }
}

/// An expectation that skips a specified number of elements from the async sequence.
public struct SkipCountExpectation: AsyncSequenceExpectation {
    public let count: Int
    public let sourceLocation: SourceLocation
    public var description: String {
        "skip \(count) element\(count == 1 ? "" : "s")"
    }

    init(count: Int, sourceLocation: SourceLocation = #_sourceLocation) {
        self.count = count
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        // Validate skip count before processing
        guard count > 0 else {
            throw AsyncTestError.invalidSkipCount(count: count, sourceLocation: sourceLocation)
        }
        // Skip expectations always match any element since they're designed to skip
        return true
    }
}
