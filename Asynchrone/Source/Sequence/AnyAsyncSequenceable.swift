import Foundation


/// An async sequence that performs type erasure by wrapping another async sequence.
///
/// If the async sequence that you wish to type erase can throw, then use `AnyThrowingAsyncSequenceable`.
public struct AnyAsyncSequenceable<Element>: AsyncSequence {

    // Private
    private var _next: () async -> Element?
    private var _makeAsyncIterator: () -> Self

    // MARK: Initialization
    
    /// Creates a type erasing async sequence.
    /// - Parameters:
    ///   - sequence: The async sequence to type erase.
    public init<T>(_ sequence: T) where T: AsyncSequence, T.Element == Element {
        var iterator = sequence.makeAsyncIterator()
        self._next = { try? await iterator.next() }
        self._makeAsyncIterator = { .init(sequence) }
    }

    /// Creates an optional type erasing async sequence.
    /// - Parameters:
    ///   - sequence: An optional async sequence to type erase.
    public init?<T>(_ asyncSequence: T?) where T: AsyncSequence, T.Element == Element {
        guard let asyncSequence = asyncSequence else { return nil }
        self = .init(asyncSequence)
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        self._makeAsyncIterator()
    }
}

// MARK: AsyncIteratorProtocol

extension AnyAsyncSequenceable: AsyncIteratorProtocol {

    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async -> Element? {
        await self._next()
    }
}




// MARK: Erasure

extension AsyncSequence {
    
    /// Creates a type erasing async sequence.
    ///
    /// If the async sequence that you wish to type erase can throw,
    /// then use `eraseToAnyThrowingAsyncSequenceable()`.
    /// - Returns: A typed erased async sequence.
    public func eraseToAnyAsyncSequenceable() -> AnyAsyncSequenceable<Element> {
        .init(self)
    }
}
