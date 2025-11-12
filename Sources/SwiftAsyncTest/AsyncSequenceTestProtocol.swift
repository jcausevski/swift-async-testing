import Testing
import Foundation

/// A protocol that provides testing capabilities for async sequences.
public protocol AsyncSequenceTestProtocol {
    associatedtype Element
}

extension AsyncSequenceTestProtocol where Self: AsyncSequence {
    /// Creates a test for this async sequence using result builder syntax.
    /// - Parameter expectations: A result builder closure that defines the expected emissions.
    public func test(@AsyncSequenceExpectationBuilder<Element> _ expectations: () -> [AsyncSequenceExpectation]) async throws {
        let context = AsyncSequenceTestContext<Element>()
        context.expectations = expectations()
        try await context.validate(against: self)
    }
}

// MARK: - AsyncSequence Extension

extension AsyncSequence {
    /// Creates a test for this async sequence using result builder syntax.
    /// - Parameter expectations: A result builder closure that defines the expected emissions.
    public func test(@AsyncSequenceExpectationBuilder<Element> _ expectations: () -> [AsyncSequenceExpectation]) async throws {
        let context = AsyncSequenceTestContext<Element>()
        context.expectations = expectations()
        try await context.validate(against: self)
    }
}
