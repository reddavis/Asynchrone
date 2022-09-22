extension AsyncStream {
    // MARK: Initialization
    
    /// Construct a AsyncStream buffering given an Element type.
    ///
    /// - Parameter elementType: The type the AsyncStream will produce.
    /// - Parameter maxBufferedElements: The maximum number of elements to
    ///   hold in the buffer past any checks for continuations being resumed.
    /// - Parameter build: The work associated with yielding values to the
    ///   AsyncStream.
    ///
    /// The maximum number of pending elements limited by dropping the oldest
    /// value when a new value comes in if the buffer would excede the limit
    /// placed upon it. By default this limit is unlimited.
    ///
    /// The build closure passes in a Continuation which can be used in
    /// concurrent contexts. It is thread safe to send and finish; all calls are
    /// to the continuation are serialized, however calling this from multiple
    /// concurrent contexts could result in out of order delivery.
    public init(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
        _ build: @escaping (AsyncStream<Element>.Continuation) async -> Void
    ) {
        self = AsyncStream(elementType, bufferingPolicy: limit) { continuation in
            let task = Task {
                await build(continuation)
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}



// MARK: AsyncStream.Continuation

extension AsyncStream.Continuation {
    /// Yield the provided value and then finish the stream.
    /// - Parameter value: The value to yield to the stream.
    public func finish(with value: Element) {
        self.yield(value)
        self.finish()
    }
}
