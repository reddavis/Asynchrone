import Foundation


/// An asynchronous sequence that combines three async sequences.
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
/// let streamC = .init { continuation in
///     continuation.yield(10)
///     continuation.yield(11)
///     continuation.finish()
/// }
///
/// for await value in streamA.combineLatest(streamB, streamC) {
///     print(value)
/// }
///
/// // Prints:
/// // (1, 5, 10)
/// // (2, 6, 11)
/// // (3, 7, 11)
/// // (4, 8, 11)
/// // (4, 9, 11)
/// ```
public struct CombineLatest3AsyncSequence<P: AsyncSequence, Q: AsyncSequence, R: AsyncSequence>: AsyncSequence {
    
    /// The kind of elements streamed.
    public typealias Element = (P.Element, Q.Element, R.Element)
    
    // Private
    private let p: P
    private let q: Q
    private let r: R
    
    private var iteratorP: P.AsyncIterator
    private var iteratorQ: Q.AsyncIterator
    private var iteratorR: R.AsyncIterator
    
    private var previousElementP: P.Element?
    private var previousElementQ: Q.Element?
    private var previousElementR: R.Element?
    
    // MARK: Initialization
    
    /// Creates an async sequence that only emits elements that don’t match the previous element,
    /// as evaluated by a provided closure.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    ///   - r: An async sequence.
    public init(
        _ p: P,
        _ q: Q,
        _ r: R
    ) {
        self.p = p
        self.iteratorP = p.makeAsyncIterator()
        
        self.q = q
        self.iteratorQ = q.makeAsyncIterator()
        
        self.r = r
        self.iteratorR = r.makeAsyncIterator()
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        .init(self.p, self.q, self.r)
    }
}

// MARK: AsyncIteratorProtocol

extension CombineLatest3AsyncSequence: AsyncIteratorProtocol {
    
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
        let elementR = try await self.iteratorR.next()
        
        // All streams have reached their end.
        if elementP == nil && elementQ == nil && elementR == nil {
            return nil
        }
        
        guard
            let unwrappedElementP = elementP ?? self.previousElementP,
            let unwrappedElementQ = elementQ ?? self.previousElementQ,
            let unwrappedElementR = elementR ?? self.previousElementR else {
                // This would happen if one or more streams had no elements to emit but another
                // stream had elements.
                //
                // Combine Latest only emits when it has values from all streams.
                self.previousElementP = elementP ?? self.previousElementP
                self.previousElementQ = elementQ ?? self.previousElementQ
                self.previousElementR = elementR ?? self.previousElementR
                return nil
            }
        
        self.previousElementP = unwrappedElementP
        self.previousElementQ = unwrappedElementQ
        self.previousElementR = unwrappedElementR
        
        return (unwrappedElementP, unwrappedElementQ, unwrappedElementR)
    }
}



// MARK: Combine latest

extension AsyncSequence {

    /// Combine three async sequences.
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
    /// let streamC = .init { continuation in
    ///     continuation.yield(10)
    ///     continuation.yield(11)
    ///     continuation.finish()
    /// }
    ///
    /// for await value in streamA.combineLatest(streamB, streamC) {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // (1, 5, 10)
    /// // (2, 6, 11)
    /// // (3, 7, 11)
    /// // (4, 8, 11)
    /// // (4, 9, 11)
    /// ```
    /// - Parameters:
    ///   - q: Another async sequence to combine with.
    ///   - r: Another async sequence to combine with.
    /// - Returns: A async sequence combines elements from all sequences.
    public func combineLatest<Q, R>(
        _ q: Q,
        _ r: R
    ) -> CombineLatest3AsyncSequence<Self, Q, R> where Q: AsyncSequence, R: AsyncSequence {
        .init(self, q, r)
    }
}
