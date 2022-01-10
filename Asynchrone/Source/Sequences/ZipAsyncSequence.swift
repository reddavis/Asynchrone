import Foundation


/// An asynchronous sequence that applys a zip function to the two async sequences.
///
/// Use `ZipAsyncSequence` to combine the latest elements from two async sequences and emit a tuple.
///
/// The async sequence waits until both provided async sequences have emitted an element,
/// then emits both elements as a tuple.
///
/// If one sequence never emits a value or raises an error then the zipped sequence will finish.
///
/// ```swift
/// let streamA = .init { continuation in
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.finish()
/// }
///
/// let streamB = .init { continuation in
///     continuation.yield(5)
///     continuation.yield(6)
///     continuation.yield(7)
///     continuation.finish()
/// }
///
/// for await value in streamA.zip(streamB) {
///     print(value)
/// }
///
/// // Prints:
/// // (1, 5)
/// // (2, 6)
/// ```
public struct ZipAsyncSequence<P: AsyncSequence, Q: AsyncSequence>: AsyncSequence {
    
    /// The kind of elements streamed.
    public typealias Element = (P.Element, Q.Element)
    
    // Private
    private let p: P
    private let q: Q
    
    private var iteratorP: P.AsyncIterator
    private var iteratorQ: Q.AsyncIterator
    
    // MARK: Initialization
    
    /// Creates an async sequence that zips and emits the elements from the provided async sequences.
    /// - Parameters:
    ///   - p: An async sequence.
    ///   - q: An async sequence.
    init(
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

extension ZipAsyncSequence: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    ///
    /// Continues to call `next()` on it's base iterator and iterator of
    /// it's combined sequence.
    ///
    /// If any iterator returns `nil`, indicating the end of the sequence, this
    /// iterator returns `nil`.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async rethrows -> Element? {
        let elementP = try await self.iteratorP.next()
        let elementQ = try await self.iteratorQ.next()
        
        // If any sequence reaches the end, then this sequence finishes.
        guard
            let unwrappedElementP = elementP,
            let unwrappedElementQ = elementQ else {
                return nil
            }
        
        return (unwrappedElementP, unwrappedElementQ)
    }
}



// MARK: Zip

extension AsyncSequence {

    /// Create an asynchronous sequence that applys a zip function to the two async sequences.
    ///
    /// Combines the latest elements from two async sequences and emits a tuple.
    ///
    /// The async sequence waits until both provided async sequences have emitted an element,
    /// then emits both elements as a tuple.
    ///
    /// If one sequence never emits a value or raises an error then the zipped sequence will finish.
    ///
    /// ```swift
    /// let streamA = .init { continuation in
    ///     continuation.yield(1)
    ///     continuation.yield(2)
    ///     continuation.finish()
    /// }
    ///
    /// let streamB = .init { continuation in
    ///     continuation.yield(5)
    ///     continuation.yield(6)
    ///     continuation.yield(7)
    ///     continuation.finish()
    /// }
    ///
    /// for await value in streamA.zip(streamB) {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // (1, 5)
    /// // (2, 6)
    /// ```
    /// - Parameters:
    ///   - other: Another async sequence to zip with.
    /// - Returns: A async sequence zips elements from this and another async sequence.
    public func zip<Q>(
        _ other: Q
    ) -> ZipAsyncSequence<Self, Q> where Q: AsyncSequence {
        .init(self, other)
    }
}
