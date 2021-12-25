//
//  Throttle.swift
//  Asynchrone
//
//  Created by Michal Zaborowski on 2021-12-24.
//

import Foundation

extension ThrottleAsyncSequence {
    private actor Inner<T: AsyncSequence> {

        public typealias Element = T.Element

        private var continuation: AsyncStream<Element>.Continuation?

        public let interval: TimeInterval

        private var collectedElements: [Element] = []

        private var lastTime: Date?
        private var base: T
        private let latest: Bool

        private var waitingTask: Task<Void, Never>?

        internal init(base: T, continuation: AsyncStream<Element>.Continuation, interval: TimeInterval, latest: Bool) {
            self.base = base
            self.continuation = continuation
            self.interval = interval
            self.latest = latest
        }

        internal func start() async {
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
                continuation?.finish()
            }
        }

        private func handle(event: T.Element) {

            collectedElements.append(event)

            guard let lastTime = lastTime else {
                self.lastTime = Date()
                if let value = latest ? collectedElements.last : collectedElements.first {
                    continuation?.yield(value)
                }
                collectedElements = []
                return
            }

            let currentTime = Date()
            let gapDuration = currentTime.timeIntervalSince(lastTime)

            if gapDuration < interval {
                guard waitingTask == nil else {
                    return
                }

                let delay = interval - gapDuration
                waitingTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await self?.finishWaitingTask()
                }

            } else {
                if let value = latest ? collectedElements.last : collectedElements.first {
                    self.lastTime = Date()
                    continuation?.yield(value)
                    collectedElements = []
                }
            }
        }

        private func finishWaitingTask() {
            waitingTask = nil

            if let value = latest ? collectedElements.last : collectedElements.first {
                lastTime = Date()
                continuation?.yield(value)
                collectedElements = []
            }
        }
    }
}

public struct ThrottleAsyncSequence<T: AsyncSequence>: AsyncSequence {

    /// The kind of elements streamed.
    public typealias Element = T.Element

    // Private
    private var base: T
    private var stream: AsyncStream<T.Element>!
    private var iterator: AsyncStream<T.Element>.Iterator!
    private var continuation: AsyncStream<T.Element>.Continuation!
    private var inner: ThrottleAsyncSequence.Inner<T>!

    // MARK: Initialization

    /// Creates an async sequence that emits an element once.
    /// - Parameters:
    ///   - element: The element to emit.
    public init(_ base: T, interval: TimeInterval, latest: Bool) {

        var streamContinuation: AsyncStream<T.Element>.Continuation!
        let stream = AsyncStream<T.Element> { (continuation: AsyncStream<T.Element>.Continuation) in
            streamContinuation = continuation
        }
        self.base = base
        self.stream = stream
        self.iterator = stream.makeAsyncIterator()
        self.continuation = streamContinuation
        self.inner = ThrottleAsyncSequence.Inner<T>(base: base, continuation: streamContinuation, interval: interval, latest: latest)

        Task { [inner] in
            await inner?.start()
        }
    }
}

// MARK: AsyncIteratorProtocol

extension ThrottleAsyncSequence: AsyncIteratorProtocol {

    public mutating func next() async -> Element? {
        await self.iterator.next()
    }

    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        iterator
    }
}

extension AsyncSequence {

    /// Emits only elements that don't match the previous element.
    /// - Returns: A `AsyncRemoveDuplicatesSequence` instance.
    public func throttle(_ interval: TimeInterval, latest: Bool) -> ThrottleAsyncSequence<Self> {
        .init(self, interval: interval, latest: latest)
    }
}
