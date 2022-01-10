import Foundation


/// An asynchronous sequence that merges two async sequences.
///
/// The sequences are iterated through in parallel.
///
/// ```swift
/// let streamA = .init { continuation in
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.yield(4)
///     continuation.finish()
/// }
///
/// let streamB = .init { continuation in
///     continuation.yield(5)
///     continuation.yield(6)
///     continuation.yield(7)
///     continuation.yield(8)
///     continuation.yield(9)
///     continuation.finish()
/// }
///
/// for await value in streamA.merge(with: streamB) {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// // 5
/// // 2
/// // 6
/// // 3
/// // 7
/// // 4
/// // 8
/// // 9
/// ```
public struct MergeAsyncSequence<T: AsyncSequence>: AsyncSequence {
    
    /// The kind of elements streamed.
    public typealias Element = T.Element
    
    // Private
    // swiftlint:disable implicitly_unwrapped_optional
    private var stream: AsyncStream<Element>!
    private var iterator: AsyncStream<Element>.Iterator!
    // swiftlint:enable implicitly_unwrapped_optional
    
    // MARK: Initialization
    
    /// Creates an async sequence that merges the provided async sequence's.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    public init(
        _ p: T,
        _ q: T
    ) {
        self.stream = self.buildStream(p, q)
        self.iterator = self.stream.makeAsyncIterator()
    }
    
    private func buildStream(
        _ p: T,
        _ q: T
    ) -> AsyncStream<Element> {
        .init { continuation in
            let handler: (
                _ sequence: T,
                _ continuation: AsyncStream<Element>.Continuation
            ) async throws -> Void = { sequence, continuation in
                for try await event in sequence {
                    continuation.yield(event)
                }
            }
            
            async let resultA: () = handler(p, continuation)
            async let resultB: () = handler(q, continuation)
            
            _ = try? await [resultA, resultB]
            continuation.finish()
        }
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        self.iterator
    }
}

// MARK: AsyncIteratorProtocol

extension MergeAsyncSequence: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    ///
    /// Continues to call `next()` on it's base iterator and iterator of
    /// it's combined sequence.
    ///
    /// If both iterator's return `nil`, indicating the end of the sequence, this
    /// iterator returns `nil`.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async rethrows -> Element? {
        await self.iterator.next()
    }
}



// MARK: Merge

extension AsyncSequence {

    /// An asynchronous sequence that merges two async sequence.
    ///
    /// The sequences are iterated through in parallel.
    ///
    /// ```swift
    /// let streamA = .init { continuation in
    ///     continuation.yield(1)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.yield(4)
    ///     continuation.finish()
    /// }
    ///
    /// let streamB = .init { continuation in
    ///     continuation.yield(5)
    ///     continuation.yield(6)
    ///     continuation.yield(7)
    ///     continuation.yield(8)
    ///     continuation.yield(9)
    ///     continuation.finish()
    /// }
    ///
    /// for await value in streamA.merge(with: streamB) {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // 1
    /// // 5
    /// // 2
    /// // 6
    /// // 3
    /// // 7
    /// // 4
    /// // 8
    /// // 9
    /// ```
    /// - Parameters:
    ///   - other: Another async sequence to merge with.
    /// - Returns: A async sequence merges elements from this and another async sequence.
    public func merge(
        with other: Self
    ) -> MergeAsyncSequence<Self> {
        .init(self, other)
    }
}
