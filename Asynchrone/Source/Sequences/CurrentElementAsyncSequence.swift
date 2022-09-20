/// A async sequence that wraps a single value and emits a new element whenever the element changes.
///
/// ```swift
/// let sequence = CurrentElementAsyncSequence(0)
/// print(await sequence.element)
///
/// await stream.yield(1)
/// print(await sequence.element)
///
/// await stream.yield(2)
/// await stream.yield(3)
/// await stream.yield(4)
/// print(await sequence.element)
///
/// // Prints:
/// // 0
/// // 1
/// // 4
/// ```
public actor CurrentElementAsyncSequence<Element>: AsyncSequence {
    /// The element wrapped by this async sequence, emitted as a new element whenever it changes.
    public private(set) var element: Element
    
    // Private
    private let stream: _Stream<Element>

    // MARK: Initialization

    /// Creates an async sequence that emits elements only after a specified time interval elapses between emissions.
    /// - Parameters:
    ///   - element: The async sequence in which this sequence receives it's elements.
    public init(_ element: Element) {
        self.stream = .init(element)
        self.element = element
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    nonisolated public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        self.stream.makeAsyncIterator()
    }
    
    // MARK: API
    
    /// Yield a new element to the sequence.
    ///
    /// Yielding a new element will update this async sequence's `element` property
    /// along with emitting it through the sequence.
    /// - Parameter element: The element to yield.
    public func yield(_ element: Element) {
        self.stream.yield(element)
        self.element = element
    }
    
    /// Mark the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    public func finish() {
        self.stream.finish()
    }
    
    /// Emit one last element beford marking the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    /// - Parameter element: The element to emit.
    public func finish(with element: Element) {
        self.stream.finish(with: element)
        self.element = element
    }
}

// MARK: Stream

fileprivate struct _Stream<Element>: AsyncSequence {
    private var stream: AsyncStream<Element>!
    private var continuation: AsyncStream<Element>.Continuation!
    
    // MARK: Intialization
    
    fileprivate init(_ element: Element) {
        self.stream = .init { self.continuation = $0 }
        self.yield(element)
    }
    
    fileprivate func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        self.stream.makeAsyncIterator()
    }
    
    // MARK: API
    
    fileprivate func yield(_ element: Element) {
        self.continuation.yield(element)
    }
    
    fileprivate func finish() {
        self.continuation.finish()
    }
    
    fileprivate func finish(with element: Element) {
        self.continuation.finish(with: element)
    }
}
