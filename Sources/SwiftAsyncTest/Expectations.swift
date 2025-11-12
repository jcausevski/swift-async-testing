import Foundation

// MARK: - Expectation Protocols

/// A protocol for expectations about emitted values.
public protocol EmitExpectation {
    func matches(_ element: Any) throws -> Bool
    var description: String { get }
}

// MARK: - Concrete Expectation Types

public struct ValueExpectation<Element>: EmitExpectation {
    public let value: Element
    public let description: String

    init(value: Element) {
        self.value = value
        self.description = String(describing: value)
    }

    public func matches(_ element: Any) throws -> Bool {
        guard let typedElement = element as? Element else {
            return false
        }
        return String(describing: typedElement) == description
    }
}

public struct EquatableValueExpectation<E: Equatable>: EmitExpectation {
    public let value: E
    public let description: String

    init(value: E) {
        self.value = value
        self.description = String(describing: value)
    }

    public func matches(_ element: Any) throws -> Bool {
        guard let typedElement = element as? E else {
            return false
        }
        return typedElement == value
    }
}

public struct PredicateExpectation<Element>: EmitExpectation {
    public let predicate: @Sendable (Element) -> Bool
    public let description: String

    init(predicate: @escaping @Sendable (Element) -> Bool) {
        self.predicate = predicate
        self.description = "matching predicate"
    }

    public func matches(_ element: Any) throws -> Bool {
        guard let typedElement = element as? Element else {
            return false
        }
        return predicate(typedElement)
    }
}
