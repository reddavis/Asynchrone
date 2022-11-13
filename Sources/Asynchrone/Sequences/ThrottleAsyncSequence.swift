import Foundation

/// An async sequence that emits either the most-recent or first element emitted
/// by the base async sequence in a specified time interval.
///
/// ThrottleAsyncSequence selectively emits elements from a base async sequence during an
/// interval you specify. Other elements received within the throttling interval aren’t emitted.
///
/// ```swift
/// let sequence = AsyncStream<Int> { continuation in
///     continuation.yield(0)
///     try? await Task.sleep(nanoseconds: 100_000_000)
///     continuation.yield(1)
///     try? await Task.sleep(nanoseconds: 100_000_000)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.yield(4)
///     continuation.yield(5)
///     continuation.finish()
/// }
///
/// for element in try await sequence.throttle(for: 0.05, latest: true) {
///     print(element)
/// }
///
/// // Prints:
/// // 0
/// // 1
/// // 2
/// ```
public struct ThrottleAsyncSequence<T: AsyncSequence>: AsyncSequence {
    /// The kind of elements streamed.
    public typealias Element = T.Element

    // Private
    private var base: T
    private var interval: TimeInterval
    private var latest: Bool

    // MARK: Initialization

    /// Creates an async sequence that emits either the most-recent or first element
    /// emitted by the base async sequence in a specified time interval.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - interval: The interval in which to emit the most recent element.
    ///   - latest: A Boolean value indicating whether to emit the most recent element.
    ///   If false, the async sequence emits the first element received during the interval.
    public init(
        _ base: T,
        interval: TimeInterval,
        latest: Bool
    ) {
        self.base = base
        self.interval = interval
        self.latest = latest
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: self.base.makeAsyncIterator(), interval: self.interval, latest: self.latest)
    }
}

extension ThrottleAsyncSequence: Sendable
where
T: Sendable {}

// MARK: Iterator

extension ThrottleAsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        var base: T.AsyncIterator
        var interval: TimeInterval
        var latest: Bool
        
        // Private
        private var collectedElements: [Element] = []
        private var lastEmission: Date?
        
        // MARK: Initialization
        
        init(
            base: T.AsyncIterator,
            interval: TimeInterval,
            latest: Bool
        )
        {
            self.base = base
            self.interval = interval
            self.latest = latest
        }
        
        // MARK: AsyncIteratorProtocol
        
        public mutating func next() async rethrows -> Element? {
            while true {
                guard let value = try await self.base.next() else {
                    return nil
                }
                
                guard let lastEmission = self.lastEmission else {
                    self.lastEmission = Date()
                    return value
                }
                
                self.collectedElements.append(value)
                let element = (self.latest ? self.collectedElements.last : self.collectedElements.first) ?? value
                let gap = Date().timeIntervalSince(lastEmission)
                if gap >= self.interval {
                    self.lastEmission = Date()
                    self.collectedElements.removeAll()
                    return element
                }
            }
        }
    }
}

extension ThrottleAsyncSequence.Iterator: Sendable
where
T.AsyncIterator: Sendable,
T.Element: Sendable {}

// MARK: Throttle

extension AsyncSequence {

    /// Emits either the most-recent or first element emitted by the base async
    /// sequence in the specified time interval.
    ///
    /// ThrottleAsyncSequence selectively emits elements from a base async sequence during an
    /// interval you specify. Other elements received within the throttling interval aren’t emitted.
    ///
    /// ```swift
    /// let sequence = AsyncStream<Int> { continuation in
    ///     continuation.yield(0)
    ///     try? await Task.sleep(nanoseconds: 100_000_000)
    ///     continuation.yield(1)
    ///     try? await Task.sleep(nanoseconds: 100_000_000)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.yield(4)
    ///     continuation.yield(5)
    ///     continuation.finish()
    /// }
    ///
    /// for element in try await sequence.throttle(for: 0.05, latest: true) {
    ///     print(element)
    /// }
    ///
    /// // Prints:
    /// // 0
    /// // 1
    /// // 2
    /// ```
    /// - Parameters:
    ///   - interval: The interval in which to emit the most recent element.
    ///   - latest: A Boolean value indicating whether to emit the most recent element.
    /// - Returns: A `ThrottleAsyncSequence` instance.
    public func throttle(for interval: TimeInterval, latest: Bool) -> ThrottleAsyncSequence<Self> {
        .init(self, interval: interval, latest: latest)
    }
}
