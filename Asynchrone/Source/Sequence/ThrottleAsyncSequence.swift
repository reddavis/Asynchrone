//
//  Throttle.swift
//  Asynchrone
//
//  Created by Michal Zaborowski on 2021-12-24.
//

import Foundation

// MARK: - ThrottleAsyncSequence

public struct ThrottleAsyncSequence<T: AsyncSequence>: AsyncSequence {

    /// The kind of elements streamed.
    public typealias Element = T.Element

    // MARK: ThrottleAsyncSequence (Private Properties)

    private var base: T
    private var stream: AsyncThrowingStream<T.Element, Error>
    private var iterator: AsyncThrowingStream<T.Element, Error>.Iterator
    private var continuation: AsyncThrowingStream<T.Element, Error>.Continuation
    private var inner: ThrottleAsyncSequence.Inner<T>

    // MARK: ThrottleAsyncSequence (Public Properties)

    /// Creates an async sequence that emits an element once.
    /// - Parameters:
    ///   - element: The element to emit.
    public init(_ base: T, interval: TimeInterval, latest: Bool) {

        var streamContinuation: AsyncThrowingStream<T.Element, Error>.Continuation!
        let stream = AsyncThrowingStream<T.Element, Error> { (continuation: AsyncThrowingStream<T.Element, Error>.Continuation) in
            streamContinuation = continuation
        }
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

    private actor Inner<T: AsyncSequence> {

        public typealias Element = T.Element

        // MARK: Inner (Private Properties)

        private let interval: TimeInterval

        private var continuation: AsyncThrowingStream<Element, Error>.Continuation?

        private var collectedElements: [Element] = []

        private var lastTime: Date?
        private var base: T
        private let latest: Bool

        private var scheduledTask: Task<Void, Never>?

        // MARK: Inner (Internal Methods)

        deinit {
            scheduledTask?.cancel()
            continuation = nil
        }

        internal init(base: T, continuation: AsyncThrowingStream<Element, Error>.Continuation, interval: TimeInterval, latest: Bool) {
            self.base = base
            self.continuation = continuation
            self.interval = interval
            self.latest = latest
        }

        internal func startAwaitingForBaseSequence() async {
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

extension AsyncSequence {

    /// Emits only elements that don't match the previous element.
    /// - Returns: A `AsyncRemoveDuplicatesSequence` instance.
    public func throttle(_ interval: TimeInterval, latest: Bool) -> ThrottleAsyncSequence<Self> {
        .init(self, interval: interval, latest: latest)
    }
}
