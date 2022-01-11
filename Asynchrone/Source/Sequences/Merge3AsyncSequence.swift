import Foundation


/// An asynchronous sequence that merges three async sequences.
///
/// The sequences are iterated through in parallel.
///
/// ```swift
/// let streamA = .init { continuation in
///     continuation.yield(1)
///     continuation.yield(4)
///     continuation.finish()
/// }
///
/// let streamB = .init { continuation in
///     continuation.yield(2)
///     continuation.finish()
/// }
///
/// let streamC = .init { continuation in
///     continuation.yield(3)
///     continuation.finish()
/// }
///
/// for await value in self.streamA.merge(with: self.streamB, self.streamC) {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// // 2
/// // 3
/// // 4
/// ```
public struct Merge3AsyncSequence<T: AsyncSequence>: AsyncSequence {
    
    /// The kind of elements streamed.
    public typealias Element = T.Element
    
    // Private
    // swiftlint:disable implicitly_unwrapped_optional
    private var stream: AsyncThrowingStream<Element, Error>!
    private var iterator: AsyncThrowingStream<Element, Error>.Iterator!
    // swiftlint:enable implicitly_unwrapped_optional
    
    // MARK: Initialization
    
    /// Creates an async sequence that merges the provided async sequence's.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    public init(
        _ p: T,
        _ q: T,
        _ r: T
    ) {
        self.stream = self.buildStream(p, q, r)
        self.iterator = self.stream.makeAsyncIterator()
    }
    
    private func buildStream(
        _ p: T,
        _ q: T,
        _ r: T
    ) -> AsyncThrowingStream<Element, Error> {
        .init { continuation in
            let handler: (
                _ sequence: T,
                _ continuation: AsyncThrowingStream<Element, Error>.Continuation
            ) async throws -> Void = { sequence, continuation in
                for try await event in sequence {
                    continuation.yield(event)
                }
            }
            
            async let resultP: () = handler(p, continuation)
            async let resultQ: () = handler(q, continuation)
            async let resultR: () = handler(r, continuation)
            
            do {
                _ = try await [resultP, resultQ, resultR]
                continuation.finish()
            }
            catch {
                continuation.finish(throwing: error)
            }
        }
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.Iterator {
        self.iterator
    }
}

// MARK: AsyncIteratorProtocol

extension Merge3AsyncSequence: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    ///
    /// Continues to call `next()` on it's base iterator and iterator of
    /// it's combined sequence.
    ///
    /// If both iterator's return `nil`, indicating the end of the sequence, this
    /// iterator returns `nil`.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async rethrows -> Element? {
        do {
            return try await self.iterator.next()
        }
        catch {
            return nil
        }
    }
}




// MARK: Merge

extension AsyncSequence {

    /// An asynchronous sequence that merges three async sequences.
    ///
    /// The sequences are iterated through in parallel.
    ///
    /// ```swift
    /// let streamA = .init { continuation in
    ///     continuation.yield(1)
    ///     continuation.yield(4)
    ///     continuation.finish()
    /// }
    ///
    /// let streamB = .init { continuation in
    ///     continuation.yield(2)
    ///     continuation.finish()
    /// }
    ///
    /// let streamC = .init { continuation in
    ///     continuation.yield(3)
    ///     continuation.finish()
    /// }
    ///
    /// for await value in streamA.merge(with: streamB, streamC) {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // 1
    /// // 2
    /// // 3
    /// // 4
    /// ```
    /// - Parameters:
    ///   - q: An async sequence.
    ///   - r: An async sequence.
    /// - Returns: A async sequence merges elements from this and another async sequence.
    public func merge(
        with q: Self,
        _ r: Self
    ) -> Merge3AsyncSequence<Self> {
        .init(self, q, r)
    }
}
