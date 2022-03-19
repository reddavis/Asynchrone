import Foundation


/// An async sequence that emits the current date on a given interval.
///
/// ```swift
/// let sequence = TimerAsyncSequence(interval: 1)
///
/// let start = Date.now
/// for element in await sequence {
///     print(element)
/// }
///
/// // Prints:
/// // 2022-03-19 20:49:30 +0000
/// // 2022-03-19 20:49:31 +0000
/// // 2022-03-19 20:49:32 +0000
/// ```
public final class TimerAsyncSequence: AsyncSequence {

    /// The kind of elements streamed.
    public typealias Element = Date

    // Private
    private let interval: TimeInterval
    private let passthroughSequence: PassthroughAsyncSequence<Element> = .init()
    private var task: Task<Void, Error>?

    // MARK: Initialization

    /// Creates an async sequence that emits the current date on a given interval.
    /// - Parameters:
    ///   - interval: The interval on which to emit elements.
    public init(interval: TimeInterval) {
        self.interval = interval
    }
    
    // MARK: Timer
    
    private func start() {
        self.task = Task { [interval, passthroughSequence] in
            do {
                while !Task.isCancelled {
                    try await Task.sleep(seconds: interval)
                    passthroughSequence.yield(Date())
                }
            } catch is CancellationError {
                passthroughSequence.finish()
            } catch {
                throw error
            }
        }
    }
    
    /// Cancel the sequence from emitting anymore elements.
    public func cancel() {
        self.task?.cancel()
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> PassthroughAsyncSequence<Element>.AsyncIterator {
        self.start()
        return self.passthroughSequence.makeAsyncIterator()
    }
}
