/// Catches any errors in the async sequence and replaces it
/// with the provided async sequence.
///
/// ```swift
/// let sequence = Fail<Int, TestError>(
///     error: TestError()
/// )
/// .catch { error in
///     Just(-1)
/// }
///
/// for await value in sequence {
///     print(value)
/// }
///
/// // Prints:
/// // -1
/// ```
public struct CatchErrorAsyncSequence<Base, NewAsyncSequence>: AsyncSequence where
Base: AsyncSequence,
NewAsyncSequence: AsyncSequence,
Base.Element == NewAsyncSequence.Element {
    /// The kind of elements streamed.
    public typealias Element = Base.Element
    
    // Private
    private let base: Base
    private let handler: (Error) -> NewAsyncSequence
    private var iterator: Base.AsyncIterator
    private var caughtIterator: NewAsyncSequence.AsyncIterator?
    
    // MARK: Initialization
    
    /// Creates an async sequence that replaces any errors in the sequence with a provided element.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - output: The element with which to replace errors from the base async sequence.
    public init(
        base: Base,
        handler: @escaping (Error) -> NewAsyncSequence
    ) {
        self.base = base
        self.handler = handler
        self.iterator = base.makeAsyncIterator()
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        .init(base: self.base, handler: self.handler)
    }
}

// MARK: AsyncIteratorProtocol

extension CatchErrorAsyncSequence: AsyncIteratorProtocol {
    public mutating func next() async -> Element? {
        if self.caughtIterator != nil {
            return try? await self.caughtIterator?.next()
        }
        
        do {
            return try await self.iterator.next()
        } catch {
            self.caughtIterator = self.handler(error).makeAsyncIterator()
            return await self.next()
        }
    }
}

// MARK: Catch error

extension AsyncSequence {
    /// Catches any errors in the async sequence and replaces it
    /// with the provided async sequence.
    ///
    /// ```swift
    /// let sequence = Fail<Int, TestError>(
    ///     error: TestError()
    /// )
    /// .catch { error in
    ///     Just(-1)
    /// }
    ///
    /// for await value in sequence {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // -1
    /// ```
    ///
    /// - Parameter handler: A closure that takes an Error and returns a new async sequence.
    /// - Returns: A `CatchErrorAsyncSequence` instance.
    public func `catch`<S>(
        _ handler: @escaping (Error) -> S
    ) -> CatchErrorAsyncSequence<Self, S> where S: AsyncSequence, S.Element == Self.Element {
        .init(base: self, handler: handler)
    }
}
