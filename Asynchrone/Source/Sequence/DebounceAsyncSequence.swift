import Foundation


/// A async sequence that emits elements only after a specified time interval elapses between emissions.
///
/// Use `DebounceAsyncSequence` async sequence to control the number of values and time between
/// delivery of values from the base async sequence. This async sequence is useful to process bursty
/// or high-volume async sequences where you need to reduce the number of elements emitted to a rate you specify.
///
/// ```swift
/// let stream = AsyncStream<Int> { continuation in
///     continuation.yield(0)
///     try? await Task.sleep(nanoseconds: 200_000_000)
///     continuation.yield(1)
///     try? await Task.sleep(nanoseconds: 200_000_000)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.yield(4)
///     continuation.yield(5)
///     continuation.finish()
/// }
///
/// for element in try await self.stream.debounce(for: 0.1) {
///     print(element)
/// }
///
/// // Prints:
/// // 0
/// // 1
/// // 5
/// ```
public struct DebounceAsyncSequence<T: AsyncSequence>: AsyncSequence {

    /// The kind of elements streamed.
    public typealias Element = T.Element

    // Private
    private var base: T
    private var stream: AsyncThrowingStream<T.Element, Error>
    private var iterator: AsyncThrowingStream<T.Element, Error>.Iterator

    // MARK: Initialization

    /// Creates an async sequence that emits elements only after a specified time interval elapses between emissions.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - dueTime: The amount of time the async sequence should wait before emitting an element.
    public init(
        _ base: T,
        dueTime: TimeInterval
    ) {
        var streamContinuation: AsyncThrowingStream<T.Element, Error>.Continuation!
        let stream = AsyncThrowingStream<T.Element, Error> { streamContinuation = $0 }
        
        self.base = base
        self.stream = stream
        self.iterator = stream.makeAsyncIterator()
        
        let innerSequence = _DebounceAsyncSequence<T>(
            base: base,
            continuation: streamContinuation,
            dueTime: dueTime
        )

        Task { [innerSequence] in
            await innerSequence.startAwaitingForBaseSequence()
        }
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.Iterator {
        self.iterator
    }
}

// MARK: AsyncIteratorProtocol

extension DebounceAsyncSequence: AsyncIteratorProtocol {

    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async throws -> Element? {
        try await self.iterator.next()
    }
}



// MARK: _DebounceAsyncSequence

fileprivate actor _DebounceAsyncSequence<T: AsyncSequence> {

    fileprivate typealias Element = T.Element

    // Private
    private var base: T
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    private let dueTime: TimeInterval
    
    private var lastElement: Element?
    private var lastEmission: Date?
    private var scheduledTask: Task<Void, Never>?

    // MARK: Initialization

    fileprivate init(
        base: T,
        continuation: AsyncThrowingStream<Element, Error>.Continuation,
        dueTime: TimeInterval
    ) {
        self.base = base
        self.continuation = continuation
        self.dueTime = dueTime
    }
    
    deinit {
        self.scheduledTask?.cancel()
        self.continuation = nil
    }
    
    // MARK: API
    
    fileprivate func startAwaitingForBaseSequence() async {
        defer { self.continuation = nil }
        
        do {
            for try await element in self.base {
                self.handle(element: element)
            }
            
            // Reached the end of the base sequence.
            // Cancel the scheduled task and emit the final element.
            if
                let scheduledTask = self.scheduledTask,
                !scheduledTask.isCancelled,
                let lastElement = self.lastElement,
                let lastEmission = self.lastEmission
            {
                self.scheduledTask?.cancel()
                
                let delay = UInt64(self.dueTime - Date.now.timeIntervalSince(lastEmission)) * 1_000_000_000
                try? await Task.sleep(nanoseconds: delay)
                self.continuation?.finish(with: lastElement)
            } else {
                self.continuation?.finish()
            }
        } catch {
            self.continuation?.finish(throwing: error)
        }
    }

    // MARK: Element handling

    private func handle(element: T.Element) {
        // Cancel previous task
        self.scheduledTask?.cancel()
        
        // Restart scheduled task
        self.lastElement = element
        self.lastEmission = .now
        
        self.scheduledTask = Task { [dueTime, element, continuation] in
            try? await Task.sleep(nanoseconds: UInt64(dueTime * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            continuation?.yield(element)
        }
    }
}




// MARK: Throttle

extension AsyncSequence {

    /// Emits elements only after a specified time interval elapses between emissions.
    ///
    /// Use the `debounce` operator to control the number of values and time between
    /// delivery of values from the base async sequence. This operator is useful to process bursty
    /// or high-volume async sequences where you need to reduce the number of elements emitted to a rate you specify.
    ///
    /// ```swift
    /// let stream = AsyncStream<Int> { continuation in
    ///     continuation.yield(0)
    ///     try? await Task.sleep(nanoseconds: 200_000_000)
    ///     continuation.yield(1)
    ///     try? await Task.sleep(nanoseconds: 200_000_000)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.yield(4)
    ///     continuation.yield(5)
    ///     continuation.finish()
    /// }
    ///
    /// for element in try await self.stream.debounce(for: 0.1) {
    ///     print(element)
    /// }
    ///
    /// // Prints:
    /// // 0
    /// // 1
    /// // 5
    /// ```
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - dueTime: The amount of time the async sequence should wait before emitting an element.
    /// - Returns: A `DebounceAsyncSequence` instance.
    public func debounce(for dueTime: TimeInterval) -> DebounceAsyncSequence<Self> {
        .init(self, dueTime: dueTime)
    }
}
