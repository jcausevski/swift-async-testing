import Foundation

/// A result builder for constructing async sequence test expectations.
@resultBuilder
public struct AsyncSequenceExpectationBuilder<Element> {
    public static func buildBlock(_ components: AsyncSequenceExpectation...) -> [AsyncSequenceExpectation] {
        components
    }

    public static func buildArray(_ components: [AsyncSequenceExpectation]) -> [AsyncSequenceExpectation] {
        components
    }

    public static func buildOptional(_ component: AsyncSequenceExpectation?) -> [AsyncSequenceExpectation] {
        component.map { [$0] } ?? []
    }

    public static func buildEither(first component: AsyncSequenceExpectation) -> [AsyncSequenceExpectation] {
        [component]
    }

    public static func buildEither(second component: AsyncSequenceExpectation) -> [AsyncSequenceExpectation] {
        [component]
    }
}

// MARK: - Result Builder Functions

/// Creates an expectation that the async sequence will emit the specified value.
/// - Parameter value: The expected value to be emitted.
public func emit<Element>(_ value: Element) -> AsyncSequenceExpectation {
    ValueExpectation(value: value)
}

/// Creates an expectation that the async sequence will emit a value matching the predicate.
/// - Parameter predicate: A closure that takes an element and returns whether it matches.
public func emit<Element>(where predicate: @escaping @Sendable (Element) -> Bool) -> AsyncSequenceExpectation {
    PredicateExpectation(predicate: predicate)
}

/// Creates an expectation that the async sequence will emit a value that equals the specified value using Equatable.
/// - Parameter value: The expected value to be emitted.
public func emit<E: Equatable>(_ value: E) -> AsyncSequenceExpectation {
    EquatableValueExpectation(value: value)
}

// MARK: - Skip Functions

/// Creates an expectation that skips one element from the async sequence.
/// This allows you to ignore an element and continue matching subsequent elements.
public func skip() -> AsyncSequenceExpectation {
    SkipExpectation()
}

/// Creates an expectation that skips a specified number of elements from the async sequence.
/// This allows you to ignore multiple elements and continue matching subsequent elements.
/// - Parameter count: The number of elements to skip. Must be at least 1.
public func skip(_ count: Int) -> AsyncSequenceExpectation {
    SkipCountExpectation(count: count)
}
