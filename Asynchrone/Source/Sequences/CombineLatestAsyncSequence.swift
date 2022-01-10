import Foundation


/// An asynchronous sequence that combines two async sequences.
///
/// The combined sequence emits a tuple of the most-recent elements from each sequence
/// when any of them emit a value.
///
/// If one sequence never emits a value this sequence will finish.
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
/// for await value in streamA.combineLatest(streamB) {
///     print(value)
/// }
///
/// // Prints:
/// // (1, 5)
/// // (2, 6)
/// // (3, 7)
/// // (4, 8)
/// // (4, 9)
/// ```
public struct CombineLatestAsyncSequence<P: AsyncSequence, Q: AsyncSequence>: AsyncSequence {
    
    /// The kind of elements streamed.
    public typealias Element = (P.Element, Q.Element)
    
    // Private
    private let p: P
    private let q: Q
    
    private var iteratorP: P.AsyncIterator
    private var iteratorQ: Q.AsyncIterator
    
    private var previousElementP: P.Element?
    private var previousElementQ: Q.Element?
    
    // MARK: Initialization
    
    /// Creates an async sequence that only emits elements that don’t match the previous element,
    /// as evaluated by a provided closure.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    public init(
        _ p: P,
        _ q: Q
    ) {
        self.p = p
        self.iteratorP = p.makeAsyncIterator()
        
        self.q = q
        self.iteratorQ = q.makeAsyncIterator()
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        .init(self.p, self.q)
    }
}

// MARK: AsyncIteratorProtocol

extension CombineLatestAsyncSequence: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    ///
    /// Continues to call `next()` on it's base iterator and iterator of
    /// it's combined sequence.
    ///
    /// If both iterator's return `nil`, indicating the end of the sequence, this
    /// iterator returns `nil`.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async rethrows -> Element? {
        let elementP = try await self.iteratorP.next()
        let elementQ = try await self.iteratorQ.next()
        
        // All streams have reached their end.
        if elementP == nil && elementQ == nil {
            return nil
        }
        
        guard
            let unwrappedElementP = elementP ?? self.previousElementP,
            let unwrappedElementQ = elementQ ?? self.previousElementQ else {
                // This would happen if StreamP had no elements to emit but Stream Q
                // had elements.
                //
                // Combine Latest only emits when it has values from all streams.
                self.previousElementP = elementP ?? self.previousElementP
                self.previousElementQ = elementQ ?? self.previousElementQ
                return nil
            }
        
        self.previousElementP = unwrappedElementP
        self.previousElementQ = unwrappedElementQ
        
        return (unwrappedElementP, unwrappedElementQ)
    }
}



// MARK: Combine latest

extension AsyncSequence {

    /// Combine with an additional async sequence to produce a `AsyncCombineLatest2Sequence`.
    ///
    /// The combined sequence emits a tuple of the most-recent elements from each sequence
    /// when any of them emit a value.
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
    /// for await value in self.streamA.combineLatest(self.streamB) {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // (1, 5)
    /// // (2, 6)
    /// // (3, 7)
    /// // (4, 8)
    /// // (4, 9)
    /// ```
    /// - Parameters:
    ///   - other: Another async sequence to combine with.
    /// - Returns: A async sequence combines elements from this and another async sequence.
    public func combineLatest<Q>(
        _ other: Q
    ) -> CombineLatestAsyncSequence<Self, Q> where Q: AsyncSequence {
        .init(self, other)
    }
}
