import Foundation

/// A result builder for constructing async sequence test expectations.
@resultBuilder
public struct EmitExpectationBuilder<Element> {
    public static func buildBlock(_ components: EmitExpectation...) -> [EmitExpectation] {
        components
    }

    public static func buildArray(_ components: [EmitExpectation]) -> [EmitExpectation] {
        components
    }

    public static func buildOptional(_ component: EmitExpectation?) -> [EmitExpectation] {
        component.map { [$0] } ?? []
    }

    public static func buildEither(first component: EmitExpectation) -> [EmitExpectation] {
        [component]
    }

    public static func buildEither(second component: EmitExpectation) -> [EmitExpectation] {
        [component]
    }
}

// MARK: - Result Builder Functions

/// Creates an expectation that the async sequence will emit the specified value.
/// - Parameter value: The expected value to be emitted.
public func emit<Element>(_ value: Element) -> EmitExpectation {
    ValueExpectation(value: value)
}

/// Creates an expectation that the async sequence will emit a value matching the predicate.
/// - Parameter predicate: A closure that takes an element and returns whether it matches.
public func emit<Element>(where predicate: @escaping @Sendable (Element) -> Bool) -> EmitExpectation {
    PredicateExpectation(predicate: predicate)
}

/// Creates an expectation that the async sequence will emit a value that equals the specified value using Equatable.
/// - Parameter value: The expected value to be emitted.
public func emit<E: Equatable>(_ value: E) -> EmitExpectation {
    EquatableValueExpectation(value: value)
}
