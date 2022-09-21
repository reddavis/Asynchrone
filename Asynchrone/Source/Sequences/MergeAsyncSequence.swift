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
public struct MergeAsyncSequence<T>: AsyncSequence, Sendable where T: AsyncSequence, T: Sendable {
    public typealias Element = T.Element
    
    // Private
    private let p: T
    private let q: T
    
    // MARK: Initialization
    
    /// Creates an async sequence that merges the provided async sequence's.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    public init(
        _ p: T,
        _ q: T
    ) {
        self.p = p
        self.q = q
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Iterator {
        Iterator(self.p, self.q)
    }
}

// MARK: Iterator

extension MergeAsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        private var _iterator: AsyncThrowingStream<Element, Error>.Iterator!
        
        // MARK: Initialization
        
        init(
            _ p: T,
            _ q: T
        ) {
            let stream = self.merge(p, q)
            self._iterator = stream.makeAsyncIterator()
        }
        
        // MARK: Merge
        
        private func merge(
            _ p: T,
            _ q: T
        ) -> AsyncThrowingStream<Element, Error> {
            .init { continuation in
                let handler: @Sendable (
                    _ sequence: T,
                    _ continuation: AsyncThrowingStream<Element, Error>.Continuation
                ) async throws -> Void = { sequence, continuation in
                    for try await event in sequence {
                        continuation.yield(event)
                    }
                }
                
                async let resultA: () = handler(p, continuation)
                async let resultB: () = handler(q, continuation)
                
                do {
                    _ = try await [resultA, resultB]
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        
        // MARK: AsyncIteratorProtocol
        
        public mutating func next() async rethrows -> Element? {
            var result: Result<Element?, Error>
            do {
                result = .success(try await self._iterator.next())
            } catch {
                result = .failure(error)
            }
            
            switch result {
            case .success(let element):
                return element
            case .failure:
                try result._rethrowError()
            }
        }
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
    ) -> MergeAsyncSequence<Self> where Self: Sendable {
        .init(self, other)
    }
}
