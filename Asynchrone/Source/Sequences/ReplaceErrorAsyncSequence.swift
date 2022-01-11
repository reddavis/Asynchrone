import Foundation


/// An async sequence that replaces any errors in the sequence with a provided element.
///
/// ```swift
/// let sequence = Fail<Int, TestError>(
///     error: TestError()
/// )
/// .replaceError(with: 0)
///
/// for await value in stream {
///     print(value)
/// }
///
/// // Prints:
/// // 0
/// ```
public struct ReplaceErrorAsyncSequence<Base: AsyncSequence>: AsyncSequence {
    
    /// The kind of elements streamed.
    public typealias Element = Base.Element
    
    // Private
    private let base: Base
    private let replacement: Element
    private var iterator: Base.AsyncIterator
    
    // MARK: Initialization
    
    /// Creates an async sequence that replaces any errors in the sequence with a provided element.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - output: The element with which to replace errors from the base async sequence.
    public init(base: Base, output: Element) {
        self.base = base
        self.replacement = output
        self.iterator = base.makeAsyncIterator()
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        .init(base: self.base, output: self.replacement)
    }
}

// MARK: AsyncIteratorProtocol

extension ReplaceErrorAsyncSequence: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async -> Element? {
        do {
            return try await self.iterator.next()
        } catch {
            return self.replacement
        }
    }
}



// MARK: Replace error

extension AsyncSequence {
    
    /// Replaces any errors in the async sequence with the provided element.
    ///
    /// ```swift
    /// let sequence = Fail<Int, TestError>(
    ///     error: TestError()
    /// )
    /// .replaceError(with: 0)
    ///
    /// for await value in stream {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // 0
    /// ```
    /// - Parameter output: The element with which to replace errors from the base async sequence.
    /// - Returns: A `ReplaceErrorAsyncSequence` instance.
    public func replaceError(with output: Element) -> ReplaceErrorAsyncSequence<Self> {
        .init(base: self, output: output)
    }
}
