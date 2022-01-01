import Foundation


/// A throwing async sequence that performs type erasure by wrapping another throwing async sequence.
///
/// If the async sequence that you wish to type erase doesn't throw, then use `AnyAsyncSequenceable`.
public struct AnyThrowingAsyncSequenceable<Element>: AsyncSequence {

    // Private
    private var _next: () async throws -> Element?
    private var _makeAsyncIterator: () -> Self

    // MARK: Initialization

    /// Creates a type erasing async sequence.
    /// - Parameters:
    ///   - sequence: The async sequence to type erase.
    public init<T>(_ asyncSequence: T) where T: AsyncSequence, T.Element == Element {
        var iterator = asyncSequence.makeAsyncIterator()
        self._next = { try await iterator.next() }
        self._makeAsyncIterator = { .init(asyncSequence) }
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

extension AnyThrowingAsyncSequenceable: AsyncIteratorProtocol {

    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async throws -> Element? {
        try await self._next()
    }
}




// MARK: Erasure

extension AsyncSequence {

    /// Creates a throwing type erasing async sequence.
    ///
    /// If the async sequence that you wish to type erase deson't throw,
    /// then use `eraseToAnyAsyncSequenceable()`.
    /// - Returns: A typed erased async sequence.
    public func eraseToAnyThrowingAsyncSequenceable() -> AnyThrowingAsyncSequenceable<Element> {
        .init(self)
    }
}
