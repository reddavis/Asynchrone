import Foundation


/// An async sequence that emits either the most-recent or first element emitted
/// by the base async sequence in a specified time interval.
///
/// ThrottleAsyncSequence selectively emits elements from a base async sequence during an
/// interval you specify. Other elements received within the throttling interval aren’t emitted.
///
/// ```swift
/// let stream = AsyncStream<Int> { continuation in
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
/// for element in try await self.stream.throttle(for: 0.05, latest: true) {
///     print(element)
/// }
///
/// // Prints:
/// // 0
/// // 1
/// // 2
/// // 5
/// ```
public struct ThrottleAsyncSequence<T: AsyncSequence>: AsyncSequence {

    /// The kind of elements streamed.
    public typealias Element = T.Element

    // MARK: ThrottleAsyncSequence (Private Properties)

    private var base: T
    private var stream: AsyncThrowingStream<T.Element, Error>
    private var iterator: AsyncThrowingStream<T.Element, Error>.Iterator
    private var continuation: AsyncThrowingStream<T.Element, Error>.Continuation
    private var inner: ThrottleAsyncSequence.Inner<T>

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
        var streamContinuation: AsyncThrowingStream<T.Element, Error>.Continuation!
        let stream = AsyncThrowingStream<T.Element, Error> { streamContinuation = $0 }
        
        self.base = base
        self.stream = stream
        self.iterator = stream.makeAsyncIterator()
        self.continuation = streamContinuation
        self.inner = ThrottleAsyncSequence.Inner<T>(
            base: base,
            continuation: streamContinuation,
            interval: interval,
            latest: latest
        )

        Task { [inner] in
            await inner.startAwaitingForBaseSequence()
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

extension ThrottleAsyncSequence: AsyncIteratorProtocol {

    /// Produces the next element in the sequence.
    /// - Returns: The next element or `nil` if the end of the sequence is reached.
    public mutating func next() async throws -> Element? {
        try await self.iterator.next()
    }
}



// MARK: ThrottleAsyncSequence > Inner

extension ThrottleAsyncSequence {

    fileprivate actor Inner<T: AsyncSequence> {

        fileprivate typealias Element = T.Element

        // Private
        private var base: T
        private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
        private let interval: TimeInterval
        private let latest: Bool
        
        private var collectedElements: [Element] = []
        private var lastEmission: Date?

        // MARK: Initialization

        fileprivate init(
            base: T,
            continuation: AsyncThrowingStream<Element, Error>.Continuation,
            interval: TimeInterval,
            latest: Bool
        ) {
            self.base = base
            self.continuation = continuation
            self.interval = interval
            self.latest = latest
        }
        
        deinit {
            self.continuation = nil
        }
        
        // MARK: API
        
        fileprivate func startAwaitingForBaseSequence() async {
            defer { self.continuation = nil }
            
            do {
                for try await element in self.base {
                    self.handle(element: element)
                }
                
                if let lastTime = self.lastEmission {
                    let gap = Date.now.timeIntervalSince(lastTime)
                    if gap < self.interval {
                        let delay = self.interval - gap
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }

                self.emitNextElement()
                self.continuation?.finish()
            } catch {
                self.continuation?.finish(throwing: error)
            }
        }

        // MARK: Inner (Private Methods)
        
        private func nextElement() -> T.Element? {
            self.latest
            ? self.collectedElements.last
            : self.collectedElements.first
        }

        private func handle(element: T.Element) {
            self.collectedElements.append(element)

            guard let lastTime = self.lastEmission else {
                self.emitNextElement()
                return
            }

            let gap = Date.now.timeIntervalSince(lastTime)
            if gap >= self.interval {
                self.emitNextElement()
            }
        }

        private func emitNextElement() {
            self.lastEmission = Date()
            if let element = self.nextElement() {
                self.continuation?.yield(element)
            }
            self.collectedElements = []
        }
    }
}



// MARK: Throttle

extension AsyncSequence {

    /// Emits either the most-recent or first element emitted by the base async
    /// sequence in the specified time interval.
    ///
    /// ThrottleAsyncSequence selectively emits elements from a base async sequence during an
    /// interval you specify. Other elements received within the throttling interval aren’t emitted.
    ///
    /// ```swift
    /// let stream = AsyncStream<Int> { continuation in
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
    /// for element in try await self.stream.throttle(for: 0.05, latest: true) {
    ///     print(element)
    /// }
    ///
    /// // Prints:
    /// // 0
    /// // 1
    /// // 2
    /// // 5
    /// ```
    /// - Parameters:
    ///   - interval: The interval in which to emit the most recent element.
    ///   - latest: A Boolean value indicating whether to emit the most recent element.
    /// - Returns: A `ThrottleAsyncSequence` instance.
    public func throttle(for interval: TimeInterval, latest: Bool) -> ThrottleAsyncSequence<Self> {
        .init(self, interval: interval, latest: latest)
    }
}
