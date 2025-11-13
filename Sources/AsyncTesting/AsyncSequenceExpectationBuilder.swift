import Foundation
import Testing

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

/// Creates an expectation that the async sequence will emit a value matching the predicate.
/// - Parameter predicate: A closure that takes an element and returns whether it matches.
public func emit<Element>(where predicate: @escaping @Sendable (Element) -> Bool, sourceLocation: SourceLocation = #_sourceLocation) -> AsyncSequenceExpectation {
    PredicateExpectation(predicate: predicate, sourceLocation: sourceLocation)
}

/// Creates an expectation that the async sequence will emit a value that equals the specified value using Equatable.
/// - Parameter value: The expected value to be emitted.
public func emit<E: Equatable>(_ value: E, sourceLocation: SourceLocation = #_sourceLocation) -> AsyncSequenceExpectation {
    EquatableValueExpectation(value: value, sourceLocation: sourceLocation)
}

// MARK: - Skip Functions

/// Creates an expectation that skips one element from the async sequence.
/// This allows you to ignore an element and continue matching subsequent elements.
public func skip(sourceLocation: SourceLocation = #_sourceLocation) -> AsyncSequenceExpectation {
    SkipExpectation(sourceLocation: sourceLocation)
}

/// Creates an expectation that skips a specified number of elements from the async sequence.
/// This allows you to ignore multiple elements and continue matching subsequent elements.
/// - Parameter count: The number of elements to skip. Must be greater than 0.
public func skip(_ count: Int, sourceLocation: SourceLocation = #_sourceLocation) -> AsyncSequenceExpectation {
    SkipCountExpectation(count: count, sourceLocation: sourceLocation)
}
