import Foundation
import Testing

/// An expectation that skips a single element from the async sequence.
public struct SkipExpectation: AsyncSequenceExpectation {
    public let description: String = "skip element"
    public let sourceLocation: SourceLocation

    public init(sourceLocation: SourceLocation = #_sourceLocation) {
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
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
        guard count > 0 else {
            throw AsyncTestError.invalidSkipCount(count: count, sourceLocation: sourceLocation)
        }
        return true
    }
}

/// An expectation that skips all remaining elements from the async sequence.
public struct SkipAllExpectation: AsyncSequenceExpectation {
    public let description: String = "skip all remaining elements"
    public let sourceLocation: SourceLocation

    public init(sourceLocation: SourceLocation = #_sourceLocation) {
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        return true
    }
}

/// An expectation that skips elements from the async sequence while they match the predicate.
/// Elements are skipped until the predicate returns false, then the next element is matched against subsequent expectations.
public struct PredicateSkipExpectation<Element>: AsyncSequenceExpectation {
    public let predicate: @Sendable (Element) -> Bool
    public let description: String
    public let sourceLocation: SourceLocation

    init(predicate: @escaping @Sendable (Element) -> Bool, sourceLocation: SourceLocation = #_sourceLocation) {
        self.predicate = predicate
        self.description = "skip while matching predicate"
        self.sourceLocation = sourceLocation
    }

    public func matches(_ element: Any) throws -> Bool {
        guard let typedElement = element as? Element else {
            return false
        }
        return predicate(typedElement)
    }
}
