import Foundation

// MARK: - Expectation Protocols

/// A protocol for expectations about async sequence elements.
public protocol AsyncSequenceExpectation {
    func matches(_ element: Any) throws -> Bool
    var description: String { get }
}

// MARK: - Concrete Expectation Types

public struct ValueExpectation<Element>: AsyncSequenceExpectation {
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

public struct EquatableValueExpectation<E: Equatable>: AsyncSequenceExpectation {
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

public struct PredicateExpectation<Element>: AsyncSequenceExpectation {
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

// MARK: - Skip Expectations

/// An expectation that skips a single element from the async sequence.
public struct SkipExpectation: AsyncSequenceExpectation {
    public let description: String = "skip element"

    public init() {}

    public func matches(_ element: Any) throws -> Bool {
        // Skip expectations always match any element since they're designed to skip
        return true
    }
}

/// An expectation that skips a specified number of elements from the async sequence.
public struct SkipCountExpectation: AsyncSequenceExpectation {
    public let count: Int
    public var description: String {
        "skip \(count) element\(count == 1 ? "" : "s")"
    }

    init(count: Int) {
        self.count = count
    }

    public func matches(_ element: Any) throws -> Bool {
        // Validate skip count before processing
        guard count > 0 else {
            throw AsyncTestError.invalidSkipCount(count: count)
        }
        // Skip expectations always match any element since they're designed to skip
        return true
    }
}
