/// A async sequence that broadcasts elements.
///
/// ```swift
/// let sequence = ThrowingPassthroughAsyncSequence<Int>()
/// sequence.yield(0)
/// sequence.yield(1)
/// sequence.yield(2)
/// sequence.finish(throwing: TestError())
///
/// do {
///     for try await value in sequence {
///       print(value)
///     }
/// } catch {
///     print("Error!")
/// }
///
/// // Prints:
/// // 0
/// // 1
/// // 2
/// // Error!
/// ```
public struct ThrowingPassthroughAsyncSequence<Element>: AsyncSequence {
    
    // Private
    private var stream: AsyncThrowingStream<Element, Error>!
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation!

    // MARK: Initialization

    /// Creates an async sequence that broadcasts elements.
    public init() {
        self.stream = .init { self.continuation = $0 }
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.Iterator {
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
    
    /// Mark the sequence as finished by having it's iterator throw the provided error.
    ///
    /// Once finished, any calls to yield will result in no change.
    /// - Parameter error: The error to throw.
    public func finish(throwing error: Error) {
        self.continuation.finish(throwing: error)
    }
    
    /// Emit one last element beford marking the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    /// - Parameter element: The element to emit.
    public func finish(with element: Element) {
        self.continuation.finish(with: element)
    }
}
