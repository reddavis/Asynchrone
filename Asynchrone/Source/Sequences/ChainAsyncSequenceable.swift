/// An asynchronous sequence that chains two async sequences.
///
/// The combined sequence first emits the all the values from the first sequence
/// and then emits all values from the second.
///
/// ```swift
/// let sequenceA = AsyncStream<Int> { continuation in
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.finish()
/// }
///
/// let sequenceB = AsyncStream<Int> { continuation in
///     continuation.yield(4)
///     continuation.yield(5)
///     continuation.yield(6)
///     continuation.finish()
/// }
///
/// let sequenceC = AsyncStream<Int> { continuation in
///     continuation.yield(7)
///     continuation.yield(8)
///     continuation.yield(9)
///     continuation.finish()
/// }
///
/// for await value in sequenceA <> sequenceB <> sequenceC {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// // 2
/// // 3
/// // 4
/// // 5
/// // 6
/// // 7
/// // 8
/// // 9
/// ```
public struct ChainAsyncSequence<P: AsyncSequence, Q: AsyncSequence>: AsyncSequence where P.Element == Q.Element {
    
    /// The kind of elements streamed.
    public typealias Element = P.Element
    
    // Private
    private let p: P
    private let q: Q
    
    private var iteratorP: P.AsyncIterator
    private var iteratorQ: Q.AsyncIterator
    
    // MARK: Initialization
    
    /// Creates an async sequence that combines the two async sequence.
    /// - Parameters:
    ///   - p: The first async sequence.
    ///   - q: The second async sequence.
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

extension ChainAsyncSequence: AsyncIteratorProtocol {
    
    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async rethrows -> Element? {
        if let element = try await self.iteratorP.next() {
            return element
        } else {
            return try await self.iteratorQ.next()
        }
    }
}



// MARK: Chain

precedencegroup ChainOperatorPrecedence {
    associativity: left
}
infix operator <>: ChainOperatorPrecedence

/// An asynchronous sequence that chains two async sequences.
///
/// The combined sequence first emits the all the values from the first sequence
/// and then emits all values from the second.
///
/// ```swift
/// let sequenceA = AsyncStream<Int> { continuation in
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.finish()
/// }
///
/// let sequenceB = AsyncStream<Int> { continuation in
///     continuation.yield(4)
///     continuation.yield(5)
///     continuation.yield(6)
///     continuation.finish()
/// }
///
/// let sequenceC = AsyncStream<Int> { continuation in
///     continuation.yield(7)
///     continuation.yield(8)
///     continuation.yield(9)
///     continuation.finish()
/// }
///
/// for await value in sequenceA <> sequenceB <> sequenceC {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// // 2
/// // 3
/// // 4
/// // 5
/// // 6
/// // 7
/// // 8
/// // 9
/// ```
/// - Parameters:
///   - lhs: The first async sequence to iterate through.
///   - rhs: The second async sequence to iterate through.
/// - Returns: A async sequence chains the two sequences.
extension AsyncSequence {
    public static func <><P>(
        lhs: Self,
        rhs: P
    ) -> ChainAsyncSequence<Self, P> where P: AsyncSequence {
        .init(lhs, rhs)
    }
}
