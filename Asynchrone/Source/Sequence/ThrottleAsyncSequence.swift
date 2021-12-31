import Foundation


/// An asynchronous sequence that emits either the most-recent or first element emitted
/// by the base async sequence in a specified time interval.
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
        self.inner = ThrottleAsyncSequence.Inner<T>(base: base, continuation: streamContinuation, interval: interval, latest: latest)

        Task { [inner] in
            await inner.startAwaitingForBaseSequence()
        }
    }
}

// MARK: AsyncIteratorProtocol

extension ThrottleAsyncSequence: AsyncIteratorProtocol {

    public mutating func next() async throws -> Element? {
        try await self.iterator.next()
    }

    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.Iterator {
        iterator
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
        private var lastTime: Date?
        private var scheduledTask: Task<Void, Never>?

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
            scheduledTask?.cancel()
            continuation = nil
        }
        
        // MARK: API
        
        fileprivate func startAwaitingForBaseSequence() async {
            do {
                for try await event in base {
                    handle(event: event)
                }
                
                if let element = latest ? collectedElements.last : collectedElements.first {
                    continuation?.finish(with: element)
                } else {
                    continuation?.finish()
                }
            } catch {
                continuation?.finish(throwing: error)
            }
            continuation = nil
        }

        // MARK: Inner (Private Methods)

        private func handle(event: T.Element) {
            collectedElements.append(event)

            guard let lastTime = lastTime else {
                deliverCollectedValue()
                return
            }

            let currentTime = Date()
            let gap = currentTime.timeIntervalSince(lastTime)

            if gap < interval {
                guard scheduledTask == nil else {
                    return
                }

                let delay = interval - gap
                scheduledTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    guard !Task.isCancelled else { return }

                    await self?.deliverScheduledValue()
                }

            } else {
                deliverCollectedValue()
            }
        }

        private func deliverScheduledValue() {
            scheduledTask = nil
            deliverCollectedValue()
        }

        private func deliverCollectedValue() {
            lastTime = Date()
            if let value = latest ? collectedElements.last : collectedElements.first {
                continuation?.yield(value)
            }
            collectedElements = []
        }
    }
}



// MARK: Throttle

extension AsyncSequence {

    /// Emits either the most-recent or first element emitted by the base async
    /// sequence in the specified time interval.
    /// - Parameters:
    ///   - interval: The interval in which to emit the most recent element.
    ///   - latest: A Boolean value indicating whether to emit the most recent element.
    /// - Returns: A `ThrottleAsyncSequence` instance.
    public func throttle(for interval: TimeInterval, latest: Bool) -> ThrottleAsyncSequence<Self> {
        .init(self, interval: interval, latest: latest)
    }
}
