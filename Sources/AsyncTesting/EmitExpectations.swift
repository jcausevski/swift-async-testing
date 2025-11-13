import Foundation
import Testing

/// An expectation that matches a single element from the async sequence.
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

/// An expectation that matches a predicate for the async sequence.
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
