import Foundation


/// An async version of `Sequence`. Generally used to turn any `Sequence` into
/// it's async counterpart.
///
/// ```swift
/// let sequence = [0, 1, 2, 3].async
///
/// for await value in sequence {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// // 2
/// // 3
/// ```
public struct SequenceAsyncSequence<P: Sequence>: AsyncSequence {
    /// The kind of elements streamed.
    public typealias Element = P.Element
    
    // Private
    private let sequence: P
    
    // MARK: Initialization
    
    /// Creates an async sequence that combines the two async sequence.
    /// - Parameters:
    ///   - p: A sequence.
    public init(_ sequence: P) {
        self.sequence = sequence
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> SequenceAsyncSequenceIterator<P> {
        .init(self.sequence.makeIterator())
    }
}

// MARK: SequenceAsyncSequenceIterator

public struct SequenceAsyncSequenceIterator<P: Sequence>: AsyncIteratorProtocol {
    private var iterator: P.Iterator
    
    // MARK: Initialization
    
    public init(_ iterator: P.Iterator) {
        self.iterator = iterator
    }
    
    // MARK: AsyncIteratorProtocol
    
    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async -> P.Element? {
        self.iterator.next()
    }
}

// MARK: Sequence

public extension Sequence {
    /// An async sequence that contains all the elements of
    /// the current sequence.
    ///
    /// ```swift
    /// let sequence = [0, 1, 2, 3].async
    ///
    /// for await value in sequence {
    ///     print(value)
    /// }
    ///
    /// // Prints:
    /// // 1
    /// // 2
    /// // 3
    /// ```
    var async: SequenceAsyncSequence<Self> {
        .init(self)
    }
}
