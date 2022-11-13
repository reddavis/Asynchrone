/// An asynchronous sequence that streams only elements from the base asynchronous sequence
/// that don’t match the previous element.
///
/// ```swift
/// let stream = .init { continuation in
///     continuation.yield(1)
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.finish()
/// }
///
/// for await value in stream.removeDuplicates() {
///     print(value)
/// }
///
/// // Prints:
/// // 1
/// // 2
/// // 3
/// ```
public struct RemoveDuplicatesAsyncSequence<Base: AsyncSequence>: AsyncSequence where Base.Element: Equatable {
    /// The kind of elements streamed.
    public typealias Element = Base.Element
    
    // A predicate closure for evaluating whether two elements are duplicates.
    public typealias Predicate = @Sendable (_ previous: Base.Element, _ current: Base.Element) -> Bool
    
    // Private
    private let base: Base
    private let predicate: Predicate
    
    // MARK: Initialization
    
    /// Creates an async that only emits elements that don’t match the previous element,
    /// as evaluated by a provided closure.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - predicate: A closure to evaluate whether two elements are equivalent.
    public init(
        base: Base,
        predicate: @escaping Predicate
    ) {
        self.base = base
        self.predicate = predicate
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: self.base, predicate: self.predicate)
    }
}

extension RemoveDuplicatesAsyncSequence: Sendable
where
Base: Sendable {}

// MARK: Iterator

extension RemoveDuplicatesAsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        private let predicate: Predicate
        private var iterator: Base.AsyncIterator
        private var previousElement: Base.Element?
        
        // MARK: Initialization
        
        init(
            base: Base,
            predicate: @escaping Predicate
        ) {
            self.iterator = base.makeAsyncIterator()
            self.predicate = predicate
        }
        
        // MARK: AsyncIteratorProtocol
        
        public mutating func next() async rethrows -> Element? {
            let element = try await self.iterator.next()
            let previousElement = self.previousElement
            
            // Update previous element
            self.previousElement = element
            
            guard let unwrappedElement = element,
                  let unwrappedPreviousElement = previousElement else { return element }
            
            if self.predicate(unwrappedPreviousElement, unwrappedElement) {
                return try await self.next()
            } else {
                return element
            }
        }
    }
}

extension RemoveDuplicatesAsyncSequence.Iterator: Sendable
where
Base.AsyncIterator: Sendable,
Base.Element: Sendable {}

// MARK: Remove duplicates

extension AsyncSequence where Element: Equatable {
    /// Emits only elements that don't match the previous element.
    /// - Returns: A `AsyncRemoveDuplicatesSequence` instance.
    public func removeDuplicates() -> RemoveDuplicatesAsyncSequence<Self> {
        .init(base: self) { $0 == $1 }
    }
    
    /// Omits any element that the predicate determines is equal to the previous element.
    /// - Parameter predicate: A closure to evaluate whether two elements are equivalent.
    ///   Return true from this closure to indicate that the second element is a duplicate of the first.
    /// - Returns: A `AsyncRemoveDuplicatesSequence` instance.
    public func removeDuplicates(
        by predicate: @escaping RemoveDuplicatesAsyncSequence<Self>.Predicate
    ) -> RemoveDuplicatesAsyncSequence<Self> {
        .init(base: self, predicate: predicate)
    }
}
