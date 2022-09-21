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
public struct Merge3AsyncSequence<T: AsyncSequence>: AsyncSequence, Sendable where T: Sendable {
    public typealias Element = T.Element
    
    // Private
    private let p: T
    private let q: T
    private let r: T
    
    // MARK: Initialization
    
    /// Creates an async sequence that merges the provided async sequence's.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    ///   - r: An async sequence.
    public init(
        _ p: T,
        _ q: T,
        _ r: T
    ) {
        self.p = p
        self.q = q
        self.r = r
    }
    
    private func buildStream(
        _ p: T,
        _ q: T,
        _ r: T
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
    public func makeAsyncIterator() -> Iterator {
        Iterator(self.p, self.q, self.r)
    }
}

// MARK: Iterator

extension Merge3AsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        private var _iterator: AsyncThrowingStream<Element, Error>.Iterator!
        
        // MARK: Initialization
        
        init(
            _ p: T,
            _ q: T,
            _ r: T
        ) {
            let stream = self.merge(p, q, r)
            self._iterator = stream.makeAsyncIterator()
        }
        
        // MARK: Merge
        
        private func merge(
            _ p: T,
            _ q: T,
            _ r: T
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
                
                async let resultP: () = handler(p, continuation)
                async let resultQ: () = handler(q, continuation)
                async let resultR: () = handler(r, continuation)
                
                do {
                    _ = try await [resultP, resultQ, resultR]
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
    ) -> Merge3AsyncSequence<Self> where Self: Sendable {
        .init(self, q, r)
    }
}
