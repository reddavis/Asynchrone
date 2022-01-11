import Foundation
import Combine

/// An asynchronous sequence that immediately throws an error when iterated.
///
/// Once the error has been thrown, the iterator will return nil to mark the end of the sequence.
///
/// ```swift
/// let stream = Fail<Int, TestError>(error: TestError())
///
/// do {
///     for try await value in stream {
///         print(value)
///     }
/// } catch {
///     print("Error!")
/// }
///
/// // Prints:
/// // Error!
/// ```
public struct Fail<Element, Failure>: AsyncSequence where Failure: Error {
    
    // Private
    let error: Failure
    var hasThownError = false
    
    // MARK: Initialization
    
    /// Creates an async sequence that throws an error.
    /// - Parameters:
    ///   - error: The error to throw.
    public init(error: Failure) {
        self.error = error
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        .init(error: self.error)
    }
}

// MARK: AsyncIteratorProtocol

extension Fail: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async throws -> Element? {
        defer { self.hasThownError = true }
        guard !self.hasThownError else { return nil }
        
        throw self.error
    }
}
