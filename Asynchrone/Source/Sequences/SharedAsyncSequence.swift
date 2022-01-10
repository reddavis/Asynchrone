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
public struct SharedAsyncSequence<Base: AsyncSequence>: AsyncSequence {
    public typealias AsyncIterator = AsyncThrowingStream<Base.Element, Error>.Iterator

    /// The kind of elements streamed.
    public typealias Element = Base.Element

    // Private
    private let manager: SubSequenceManager<Base>

    // MARK: SharedAsyncSequence (Public Properties)

    /// Creates a shareable async sequence that can be used across multiple tasks.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    public init(_ base: Base) {
        self.manager = SubSequenceManager<Base>(base)
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<Base.Element, Error>.Iterator {
        self.manager.makeAsyncIterator()
    }
}



// MARK: Sub sequence manager

fileprivate actor SubSequenceManager<Base: AsyncSequence>{
    
    fileprivate typealias Element = Base.Element

    // Private
    private var base: Base
    private var sequences: [ThrowingPassthroughAsyncSequence<Base.Element>] = []
    private var subscriptionTask: Task<Void, Never>?

    // MARK: Initialization

    fileprivate init(_ base: Base) {
        self.base = base
    }
    
    deinit {
        self.subscriptionTask?.cancel()
    }
    
    // MARK: API
    
    /// Creates an new stream and returns its async iterator that emits elements of base async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    nonisolated fileprivate func makeAsyncIterator() -> ThrowingPassthroughAsyncSequence<Base.Element>.AsyncIterator {
        let sequence = ThrowingPassthroughAsyncSequence<Base.Element>()
        Task { [sequence] in
            await self.add(sequence: sequence)
        }
        
        return sequence.makeAsyncIterator()
    }

    // MARK: Sequence management

    private func add(sequence: ThrowingPassthroughAsyncSequence<Base.Element>) {
        self.sequences.append(sequence)
        self.subscribeToBaseSequenceIfNeeded()
    }
    
    private func subscribeToBaseSequenceIfNeeded() {
        guard self.subscriptionTask == nil else { return }

        self.subscriptionTask = Task { [weak self, base] in
            guard let self = self else { return }

            guard !Task.isCancelled else {
                await self.sequences.forEach {
                    $0.finish(throwing: CancellationError())
                }
                return
            }

            do {
                for try await value in base {
                    await self.sequences.forEach { $0.yield(value) }
                }
                
                await self.sequences.forEach { $0.finish() }
            } catch {
                await self.sequences.forEach { $0.finish(throwing: error) }
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
