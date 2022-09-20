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
    /// The type of async iterator.
    public typealias AsyncIterator = AsyncThrowingStream<Base.Element, Error>.Iterator
    
    /// The type of elements streamed.
    public typealias Element = Base.Element
    
    // Private
    private var base: Base
    private let manager: SubSequenceManager<Base>

    // MARK: SharedAsyncSequence (Public Properties)

    /// Creates a shareable async sequence that can be used across multiple tasks.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    public init(_ base: Base) {
        self.base = base
        self.manager = SubSequenceManager<Base>(base)
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AsyncThrowingStream<Base.Element, Error>.Iterator {
        self.manager.makeAsyncIterator()
    }
}

extension SharedAsyncSequence: Sendable
where
Base: Sendable {}

// MARK: CurrentElementAsyncSequence extension

extension SharedAsyncSequence {
    /// Yield a new element to the sequence.
    ///
    /// Yielding a new element will update this async sequence's `element` property
    /// along with emitting it through the sequence.
    /// - Parameter element: The element to yield.
    public func yield<Element>(_ element: Element) async where Base == CurrentElementAsyncSequence<Element>, Element: Sendable  {
        await self.base.yield(element)
    }
    
    /// Mark the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    public func finish<Element>() async where Base == CurrentElementAsyncSequence<Element> {
        await self.base.finish()
    }
    
    /// Emit one last element beford marking the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    /// - Parameter element: The element to emit.
    public func finish<Element>(with element: Element) async where Base == CurrentElementAsyncSequence<Element>, Element: Sendable {
        await self.base.finish(with: element)
    }
    
    /// The element wrapped by this async sequence, emitted as a new element whenever it changes.
    public func element<Element>() async -> Element where Base == CurrentElementAsyncSequence<Element>, Element: Sendable {
        await self.base.element
    }
}

// MARK: PassthroughAsyncSequence extension

extension SharedAsyncSequence {
    
    /// Yield a new element to the sequence.
    ///
    /// Yielding a new element will emit it through the sequence.
    /// - Parameter element: The element to yield.
    public func yield<Element>(_ element: Element) where Base == PassthroughAsyncSequence<Element>  {
        self.base.yield(element)
    }
    
    /// Mark the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    public func finish<Element>() where Base == PassthroughAsyncSequence<Element> {
        self.base.finish()
    }
    
    /// Emit one last element beford marking the sequence as finished by having it's iterator emit nil.
    ///
    /// Once finished, any calls to yield will result in no change.
    /// - Parameter element: The element to emit.
    public func finish<Element>(with element: Element) where Base == PassthroughAsyncSequence<Element> {
        self.base.finish(with: element)
    }
}

// MARK: Sub sequence manager

fileprivate actor SubSequenceManager<Base: AsyncSequence> where Base: Sendable {
    fileprivate typealias Element = Base.Element

    // Private
    private var base: Base
    private var continuations: [String : AsyncThrowingStream<Base.Element, Error>.Continuation] = [:]
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
        let id = UUID().uuidString
        let sequence = AsyncThrowingStream<Element, Error> {
            $0.onTermination = { @Sendable _ in
                self.remove(id)
            }
            
            await self.add(id: id, continuation: $0)
        }
        
        return sequence.makeAsyncIterator()
    }

    // MARK: Sequence management
    
    nonisolated private func remove(_ id: String) {
        Task {
            await self._remove(id)
        }
    }
    
    private func _remove(_ id: String) {
        self.continuations.removeValue(forKey: id)
    }
    
    private func add(id: String, continuation: AsyncThrowingStream<Base.Element, Error>.Continuation) {
        self.continuations[id] = continuation
        self.subscribeToBaseSequenceIfNeeded()
    }
    
    private func subscribeToBaseSequenceIfNeeded() {
        guard self.subscriptionTask == nil else { return }

        self.subscriptionTask = Task { [weak self, base] in
            guard let self = self else { return }

            guard !Task.isCancelled else {
                await self.continuations.values.forEach {
                    $0.finish(throwing: CancellationError())
                }
                return
            }

            do {
                for try await value in base {
                    await self.continuations.values.forEach { $0.yield(value) }
                }
                
                await self.continuations.values.forEach { $0.finish() }
            } catch {
                await self.continuations.values.forEach { $0.finish(throwing: error) }
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
