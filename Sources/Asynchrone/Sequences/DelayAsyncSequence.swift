import Foundation

/// Delays emission of all elements by the provided interval.
///
/// ```swift
/// let stream = AsyncStream<Int> { continuation in
///     continuation.yield(0)
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.finish()
/// }
///
/// let start = Date.now
/// for element in try await self.stream.delay(for: 0.5) {
///     print("\(element) - \(Date.now.timeIntervalSince(start))")
/// }
///
/// // Prints:
/// // 0 - 0.5
/// // 1 - 1.0
/// // 2 - 1.5
/// ```
public struct DelayAsyncSequence<T: AsyncSequence>: AsyncSequence {
    /// The kind of elements streamed.
    public typealias Element = T.Element

    // Private
    private let base: T
    private let interval: TimeInterval

    // MARK: Initialization

    /// Creates an async sequence that delays emission of elements and completion.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - interval: The amount of time the async sequence should wait before emitting an element.
    public init(
        _ base: T,
        interval: TimeInterval
    ) {
        self.base = base
        self.interval = interval
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Iterator {
        Iterator(interval: self.interval, iterator: self.base.makeAsyncIterator())
    }
}

extension DelayAsyncSequence: Sendable
where
T: Sendable {}

// MARK: Iterator

extension DelayAsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        private let interval: TimeInterval
        private var iterator: T.AsyncIterator
        private var lastEmission: Date?
        
        init(interval: TimeInterval, iterator: T.AsyncIterator) {
            self.interval = interval
            self.iterator = iterator
        }
        
        public mutating func next() async rethrows -> Element? {
            defer { self.lastEmission = Date() }
            
            let lastEmission = self.lastEmission ?? Date()
            let delay = self.interval - Date().timeIntervalSince(lastEmission)
            if delay > 0 {
                try? await Task.sleep(seconds: delay)
            }
            
            return try await self.iterator.next()
        }
    }
}

extension DelayAsyncSequence.Iterator: Sendable
where
T.AsyncIterator: Sendable {}

// MARK: Delay

extension AsyncSequence {
    /// Delays emission of all elements by the provided interval.
    ///
    /// ```swift
    /// let stream = AsyncStream<Int> { continuation in
    ///     continuation.yield(0)
    ///     continuation.yield(1)
    ///     continuation.yield(2)
    ///     continuation.finish()
    /// }
    ///
    /// let start = Date.now
    /// for element in try await self.stream.delay(for: 0.5) {
    ///     print("\(element) - \(Date.now.timeIntervalSince(start))")
    /// }
    ///
    /// // Prints:
    /// // 0 - 0.5
    /// // 1 - 1.0
    /// // 2 - 1.5
    /// ```
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - interval: The amount of time the async sequence should wait before emitting an element.
    /// - Returns: A `DebounceAsyncSequence` instance.
    public func delay(for interval: TimeInterval) -> DelayAsyncSequence<Self> {
        .init(self, interval: interval)
    }
}
