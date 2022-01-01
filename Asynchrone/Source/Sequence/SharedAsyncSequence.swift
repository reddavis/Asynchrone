import Foundation


/// An async sequence that can be shared between multiple tasks.
///
/// ```swift
/// let values = [
///     "a",
///     "ab",
///     "abc",
///     "abcd"
/// ]
///
/// let stream = AsyncStream { continuation in
///     for value in values {
///         continuation.yield(value)
///     }
///     continuation.finish()
/// }
/// .shared()
///
/// Task {
///     let values = try await self.stream.collect()
///     // ...
/// }
///
/// Task.detached {
///     let values = try await self.stream.collect()
///     // ...
/// }
///
/// let values = try await self.stream.collect()
/// // ...
/// ```
public struct SharedAsyncSequence<T: AsyncSequence>: AsyncSequence {
    public typealias AsyncIterator = AsyncThrowingStream<T.Element, Error>.Iterator

    /// The kind of elements streamed.
    public typealias Element = T.Element

    // MARK: SharedAsyncSequence (Private Properties)

    private let inner: Inner<T>

    // MARK: SharedAsyncSequence (Public Properties)

    /// Creates a shareable async sequence that can be used across multiple tasks.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    public init(_ base: T) {
        self.inner = Inner<T>(base)
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<T.Element, Error>.Iterator {
        inner.makeAsyncIterator()
    }
}



// MARK: - SharedAsyncSequence > Inner

extension SharedAsyncSequence {

    fileprivate final class Inner<T: AsyncSequence> {
        
        fileprivate typealias Element = T.Element

        // MARK: Inner (Private Properties)

        private var base: T
        
        private let lock = NSLock()
        private var streams: [AsyncThrowingStream<T.Element, Error>] = []
        private var continuations: [AsyncThrowingStream<T.Element, Error>.Continuation] = []
        private var subscriptionTask: Task<Void, Never>?

        // MARK: Initialization

        fileprivate init(_ base: T) {
            self.base = base
        }
        
        deinit {
            subscriptionTask?.cancel()
        }
        
        // MARK: API
        
        /// Creates an new stream and returns its async iterator that emits elements of base async sequence.
        /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
        fileprivate func makeAsyncIterator() -> AsyncThrowingStream<T.Element, Error>.Iterator {
            var streamContinuation: AsyncThrowingStream<T.Element, Error>.Continuation!
            let stream = AsyncThrowingStream<T.Element, Error> { (continuation: AsyncThrowingStream<T.Element, Error>.Continuation) in
                streamContinuation = continuation
            }

            add(stream: stream, continuation: streamContinuation)

            return stream.makeAsyncIterator()
        }

        // MARK: Inner (Private Methods)

        private func add(
            stream: AsyncThrowingStream<T.Element, Error>,
            continuation: AsyncThrowingStream<T.Element, Error>.Continuation
        ) {
            modify {
                streams.append(stream)
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
            guard subscriptionTask == nil else { return }

            subscriptionTask = Task { [weak self, base] in
                guard let self = self else { return }

                guard !Task.isCancelled else {
                    self.modify {
                        self.continuations.forEach { $0.finish(throwing: CancellationError()) }
                    }
                    return
                }

                do {
                    for try await value in base {
                        self.modify {
                            self.continuations.forEach { $0.yield(value) }
                        }
                    }
                    self.modify {
                        self.continuations.forEach { $0.finish(throwing: nil) }
                    }
                } catch {
                    self.modify {
                        self.continuations.forEach { $0.finish(throwing: error) }
                    }
                }
            }
        }
    }
}



// MARK: Shared

extension AsyncSequence {

    /// Creates a shareable async sequence that can be used across multiple tasks.
    public func shared() -> SharedAsyncSequence<Self> {
        .init(self)
    }
}
