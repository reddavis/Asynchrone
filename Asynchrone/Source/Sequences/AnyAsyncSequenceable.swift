/// An async sequence that performs type erasure by wrapping another async sequence.
///
/// If the async sequence that you wish to type erase can throw, then use `AnyThrowingAsyncSequenceable`.
public struct AnyAsyncSequenceable<Element>: AsyncSequence, Sendable {
    private var _makeAsyncIterator: @Sendable () -> Iterator

    // MARK: Initialization
    
    /// Creates a type erasing async sequence.
    /// - Parameters:
    ///   - sequence: The async sequence to type erase.
    public init<T>(_ sequence: T)
    where T: AsyncSequence,
    T.Element == Element,
    T: Sendable {
        self._makeAsyncIterator = { Iterator(sequence.makeAsyncIterator()) }
    }

    /// Creates an optional type erasing async sequence.
    /// - Parameters:
    ///   - sequence: An optional async sequence to type erase.
    public init?<T>(_ asyncSequence: T?)
    where T: AsyncSequence,
    T.Element == Element,
    T: Sendable {
        guard let asyncSequence = asyncSequence else { return nil }
        self = .init(asyncSequence)
    }
    
    // MARK: AsyncSequence

    public func makeAsyncIterator() -> Iterator {
        self._makeAsyncIterator()
    }
}

// MARK: Iterator

extension AnyAsyncSequenceable {
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: any AsyncIteratorProtocol
        
        // MARK: Initialization
        
        public init<T>(_ iterator: T) where T: AsyncIteratorProtocol, T.Element == Element {
            self.iterator = iterator
        }
        
        // MARK: AsyncIteratorProtocol
        
        public mutating func next() async -> Element? {
            // NOTE: When `AsyncSequence`, `AsyncIteratorProtocol` get their Element as
            // their primary associated type we won't need the casting.
            // https://github.com/apple/swift-evolution/blob/main/proposals/0358-primary-associated-types-in-stdlib.md#alternatives-considered
            try? await self.iterator.next() as? Element
        }
    }
}

// MARK: Erasure

extension AsyncSequence {
    /// Creates a type erasing async sequence.
    ///
    /// If the async sequence that you wish to type erase can throw,
    /// then use `eraseToAnyThrowingAsyncSequenceable()`.
    /// - Returns: A typed erased async sequence.
    public func eraseToAnyAsyncSequenceable() -> AnyAsyncSequenceable<Element> where Self: Sendable {
        .init(self)
    }
}
