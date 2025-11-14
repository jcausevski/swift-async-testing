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

// MARK: - Emit Functions

/// Creates an expectation that the async sequence will emit a value matching the predicate.
/// - Parameter predicate: A closure that takes an element and returns whether it matches.
public func emit<Element>(
    where predicate: @escaping @Sendable (Element) -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) -> AsyncSequenceExpectation {
    PredicateExpectation(predicate: predicate, sourceLocation: sourceLocation)
}

/// Creates an expectation that the async sequence will emit a value that equals the specified value.
/// - Parameter value: The expected value to be emitted.
public func emit<E: Equatable>(
    _ value: E,
    sourceLocation: SourceLocation = #_sourceLocation
) -> AsyncSequenceExpectation {
    EquatableValueExpectation(value: value, sourceLocation: sourceLocation)
}

/// Creates an expectation that the async sequence will eventually emit a value that equals the specified value.
/// This expectation will skip elements until it finds a matching value.
/// - Parameter value: The expected value to be eventually emitted.
public func emitEventually<E: Equatable>(
    _ value: E,
    sourceLocation: SourceLocation = #_sourceLocation
) -> AsyncSequenceExpectation {
    EquatableValueEventuallyExpectation(value: value, sourceLocation: sourceLocation)
}

/// Creates an expectation that the async sequence will eventually emit a value matching the predicate.
/// This expectation will skip elements until it finds one that matches the predicate.
/// - Parameter predicate: A closure that takes an element and returns whether it matches.
public func emitEventually<Element>(
    where predicate: @escaping @Sendable (Element) -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) -> AsyncSequenceExpectation {
    PredicateEventuallyExpectation(predicate: predicate, sourceLocation: sourceLocation)
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

/// Creates an expectation that skips all remaining elements from the async sequence.
/// This allows you to ignore any remaining elements and finish the test successfully.
public func skipAll(sourceLocation: SourceLocation = #_sourceLocation) -> AsyncSequenceExpectation {
    SkipAllExpectation(sourceLocation: sourceLocation)
}

// MARK: - Error Functions

/// Creates an expectation that the async sequence will throw any error.
/// This expectation matches any error that is thrown by the sequence.
public func expectError(sourceLocation: SourceLocation = #_sourceLocation) -> AsyncSequenceExpectation {
    AnyErrorExpectation(sourceLocation: sourceLocation)
}

/// Creates an expectation that the async sequence will throw an error of the specified type.
/// This expectation matches only errors of the specified type.
/// - Parameter errorType: The expected error type.
public func expectError<E: Error>(
    _ errorType: E.Type,
    sourceLocation: SourceLocation = #_sourceLocation
) -> AsyncSequenceExpectation {
    ErrorTypeExpectation<E>(errorType, sourceLocation: sourceLocation)
}

/// Creates an expectation that the async sequence will throw an error matching the predicate.
/// This expectation matches errors that satisfy the provided predicate.
/// - Parameter predicate: A closure that takes an Error and returns whether it matches.
public func expectError(
    where predicate: @escaping @Sendable (Error) -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) -> AsyncSequenceExpectation {
    ErrorPredicateExpectation(where: predicate, sourceLocation: sourceLocation)
}
