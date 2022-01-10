import Foundation


/// A async sequence that broadcasts elements.
///
/// ```swift
/// let sequence = PassthroughAsyncSequence<Int>()
/// sequence.yield(0)
/// sequence.yield(1)
/// sequence.yield(2)
/// sequence.finish()
///
/// for await value in sequence {
///     print(value)
/// }
///
/// // Prints:
/// // 0
/// // 1
/// // 2
/// ```
public struct PassthroughAsyncSequence<Element>: AsyncSequence {
    
    // Private
    private var stream: AsyncStream<Element>!
    private var continuation: AsyncStream<Element>.Continuation!

    // MARK: Initialization

    /// Creates an async sequence that broadcasts elements.
    public init() {
        self.stream = .init { self.continuation = $0 }
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        self.stream.makeAsyncIterator()
    }
    
    // MARK: API
    
    /// Yield a new element to the sequence.
    ///
    /// Yielding a new element will update this async sequence's `element` property
    /// along with emitting it through the sequence.
    /// - Parameter element: The element to yield.
    public func yield(_ element: Element) {
        self.continuation.yield(element)
    }
    
    /// Mark the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    public func finish() {
        self.continuation.finish()
    }
    
    /// Emit one last element beford marking the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    /// - Parameter element: The element to emit.
    public func finish(with element: Element) {
        self.continuation.finish(with: element)
    }
}
