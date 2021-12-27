//
//  SharedAsyncSequence.swift
//  Asynchrone
//
//  Created by Michal Zaborowski on 2021-12-27.
//

import Foundation

// MARK: - SharedAsyncSequence

public struct SharedAsyncSequence<T: AsyncSequence>: AsyncSequence {
    public typealias AsyncIterator = AsyncThrowingStream<T.Element, Error>.Iterator

    /// The kind of elements streamed.
    public typealias Element = T.Element

    // MARK: SharedAsyncSequence (Private Properties)

    private let inner: Inner<T>

    // MARK: SharedAsyncSequence (Public Properties)

    /// Creates an async that emits elements to multiple streams.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    public init(_ base: T) {
        self.inner = Inner<T>(base)
    }

    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public __consuming func makeAsyncIterator() -> AsyncThrowingStream<T.Element, Error>.Iterator {
        inner.makeAsyncIterator()
    }
}

// MARK: - SharedAsyncSequence > Inner

extension SharedAsyncSequence {

    private final class Inner<T: AsyncSequence> {
        public typealias Element = T.Element

        // MARK: Inner (Private Properties)

        private var multicastStreams: [AsyncThrowingStream<T.Element, Error>] = []
        private var continuations: [AsyncThrowingStream<T.Element, Error>.Continuation] = []

        private var isSubscribedToBaseStream: Bool = false

        private var base: T

        private let lock = NSLock()

        // MARK: Inner (Public Methods)

        public init(_ base: T) {
            self.base = base
        }

        /// Creates an new stream and returns its async iterator that emits elements of base async sequence.
        /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
        public func makeAsyncIterator() -> AsyncThrowingStream<T.Element, Error>.Iterator {
            var streamContinuation: AsyncThrowingStream<T.Element, Error>.Continuation!
            let stream = AsyncThrowingStream<T.Element, Error> { (continuation: AsyncThrowingStream<T.Element, Error>.Continuation) in
                streamContinuation = continuation
            }
            add(stream: stream, continuation: streamContinuation)

            return stream.makeAsyncIterator()
        }

        // MARK: Inner (Private Methods)

        private func add(stream: AsyncThrowingStream<T.Element, Error>,
                         continuation: AsyncThrowingStream<T.Element, Error>.Continuation) {
            modify {
                multicastStreams.append(stream)
                continuations.append(continuation)

                subscribeToBaseStreamIfNeeded()
            }
        }

        private func modify(_ block: () -> Void) {
            lock.lock()
            block()
            lock.unlock()
        }

        private func subscribeToBaseStreamIfNeeded() {
            guard !isSubscribedToBaseStream else { return }
            isSubscribedToBaseStream = true

            Task {
                do {
                    for try await value in base {
                        modify {
                            continuations.forEach { $0.yield(value) }
                        }
                    }
                    modify {
                        continuations.forEach { $0.finish(throwing: nil) }
                    }
                } catch {
                    modify {
                        continuations.forEach { $0.finish(throwing: error) }
                    }
                }
            }
        }
    }
}

extension AsyncSequence {

    public func shared() -> SharedAsyncSequence<Self> {
        .init(self)
    }
}
