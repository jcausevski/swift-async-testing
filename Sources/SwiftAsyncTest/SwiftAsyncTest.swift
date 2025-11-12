import Testing
import Foundation

/// A protocol that provides testing capabilities for async sequences.
public protocol AsyncSequenceTestProtocol {
    associatedtype Element
}

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

extension AsyncSequenceTestProtocol where Self: AsyncSequence {
    /// Creates a test context for this async sequence.
    /// - Parameter testBlock: A closure that contains the test expectations using the DSL.
    public func test(_ testBlock: (AsyncSequenceTestContext<Element>) async throws -> Void) async throws {
        let context = AsyncSequenceTestContext<Element>()
        try await testBlock(context)
        try await context.validate(against: self)
    }

    /// Creates a test for this async sequence using result builder syntax.
    /// - Parameter expectations: A result builder closure that defines the expected emissions.
    public func test(@EmitExpectationBuilder<Element> _ expectations: () -> [EmitExpectation]) async throws {
        let context = AsyncSequenceTestContext<Element>()
        context.expectations = expectations()
        try await context.validate(against: self)
    }
}

/// A test context that captures expectations for async sequence testing.
public final class AsyncSequenceTestContext<Element> {
    internal var expectations: [any EmitExpectation] = []

    /// Adds an expectation that the async sequence will emit the specified value.
    /// - Parameter value: The expected value to be emitted.
    public func emit(_ value: Element) {
        expectations.append(ValueExpectation(value: value))
    }

    /// Adds an expectation that the async sequence will emit a value matching the predicate.
    /// - Parameter predicate: A closure that takes an element and returns whether it matches.
    public func emit(where predicate: @escaping @Sendable (Element) -> Bool) {
        expectations.append(PredicateExpectation(predicate: predicate))
    }

    /// Adds an expectation that the async sequence will emit a value that equals the specified value using Equatable.
    /// - Parameter value: The expected value to be emitted.
    public func emit(_ value: Element) where Element: Equatable {
        expectations.append(EquatableValueExpectation(value: value))
    }

    internal func validate<S: AsyncSequence>(against sequence: S) async throws where S.Element == Element {
        var iterator = sequence.makeAsyncIterator()
        var expectationIndex = 0

        while let element = try await iterator.next() {
            if expectationIndex >= expectations.count {
                throw TestError.unexpectedElement(String(describing: element))
            }

            let expectation = expectations[expectationIndex]
            if try expectation.matches(element) {
                expectationIndex += 1
            } else {
                throw TestError.expectationMismatch(
                    expected: expectation.description,
                    actual: String(describing: element),
                    at: expectationIndex
                )
            }
        }

        if expectationIndex < expectations.count {
            throw TestError.insufficientElements(
                expected: expectations.count,
                actual: expectationIndex
            )
        }
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

// MARK: - Error Types

/// Errors that can occur during async sequence testing.
public enum TestError: Error, CustomStringConvertible {
    case unexpectedElement(String)
    case expectationMismatch(expected: String, actual: String, at: Int)
    case insufficientElements(expected: Int, actual: Int)

    public var description: String {
        switch self {
        case .unexpectedElement(let element):
            return "Unexpected element received: \(element)"
        case .expectationMismatch(let expected, let actual, let index):
            return "Expectation at index \(index) failed. Expected: \(expected), but got: \(actual)"
        case .insufficientElements(let expected, let actual):
            return "Insufficient elements. Expected \(expected), but got \(actual)"
        }
    }
}

// MARK: - AsyncSequence Extension

extension AsyncSequence {
    /// Creates a test context for this async sequence.
    /// - Parameter testBlock: A closure that contains the test expectations using the DSL.
    public func test(_ testBlock: (AsyncSequenceTestContext<Element>) async throws -> Void) async throws {
        let context = AsyncSequenceTestContext<Element>()
        try await testBlock(context)
        try await context.validate(against: self)
    }

    /// Creates a test for this async sequence using result builder syntax.
    /// - Parameter expectations: A result builder closure that defines the expected emissions.
    public func test(@EmitExpectationBuilder<Element> _ expectations: () -> [EmitExpectation]) async throws {
        let context = AsyncSequenceTestContext<Element>()
        context.expectations = expectations()
        try await context.validate(against: self)
    }
}
