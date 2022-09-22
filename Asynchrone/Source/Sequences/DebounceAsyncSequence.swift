import Foundation

/// A async sequence that emits elements only after a specified time interval elapses between emissions.
///
/// Use `DebounceAsyncSequence` async sequence to control the number of values and time between
/// delivery of values from the base async sequence. This async sequence is useful to process bursty
/// or high-volume async sequences where you need to reduce the number of elements emitted to a rate you specify.
///
/// HT to [swift-async-algorithms](https://github.com/apple/swift-async-algorithms) for helping
/// realise my woes of rethrows.
///
/// ```swift
/// let sequence = AsyncStream<Int> { continuation in
///     continuation.yield(0)
///     try? await Task.sleep(seconds: 0.1)
///     continuation.yield(1)
///     try? await Task.sleep(seconds: 0.1)
///     continuation.yield(2)
///     continuation.yield(3)
///     continuation.yield(4)
///     continuation.yield(5)
///     try? await Task.sleep(seconds: 0.1)
///     continuation.finish()
/// }
///
/// for element in try await sequence.debounce(for: 0.1) {
///     print(element)
/// }
///
/// // Prints:
/// // 0
/// // 1
/// // 5
/// ```
public struct DebounceAsyncSequence<T: AsyncSequence>: AsyncSequence
where
T.AsyncIterator: Sendable,
T.Element: Sendable {
    /// The kind of elements streamed.
    public typealias Element = T.Element

    // Private
    private var base: T
    private var dueTime: TimeInterval

    // MARK: Initialization

    /// Creates an async sequence that emits elements only after a specified time interval elapses between emissions.
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - dueTime: The amount of time the async sequence should wait before emitting an element.
    public init(
        _ base: T,
        dueTime: TimeInterval
    ) {
        self.base = base
        self.dueTime = dueTime
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: self.base.makeAsyncIterator(), dueTime: self.dueTime)
    }
}

extension DebounceAsyncSequence: Sendable
where
T: Sendable {}

// MARK: Iterator

extension DebounceAsyncSequence {
    public struct Iterator: AsyncIteratorProtocol {
        private var base: T.AsyncIterator
        private var dueTime: TimeInterval
        private var resultTask: Task<RaceResult, Never>?
        
        // MARK: Initialization
        
        init(
            base: T.AsyncIterator,
            dueTime: TimeInterval
        ) {
            self.base = base
            self.dueTime = dueTime
        }
                
        // MARK: AsyncIteratorProtocol
        
        public mutating func next() async rethrows -> Element? {
            var lastResult: Result<Element?, Error>?
            var lastEmission: Date = .init()
            
            while true {
                let resultTask = self.resultTask ?? Task<RaceResult, Never> { [base] in
                    var iterator = base
                    do {
                        let value = try await iterator.next()
                        return .winner(.success(value), iterator: iterator)
                    } catch {
                        return .winner(.failure(error), iterator: iterator)
                    }
                }
                self.resultTask = nil
                
                lastEmission = Date()
                let delay = UInt64(self.dueTime - Date().timeIntervalSince(lastEmission)) * 1_000_000_000
                let sleep = Task<RaceResult, Never> {
                    try? await Task.sleep(nanoseconds: delay)
                    return .sleep
                }
                
                let tasks = [resultTask, sleep]
                let firstTask = await { () async -> Task<RaceResult, Never> in
                    let raceCoordinator = TaskRaceCoodinator<RaceResult, Never>()
                    return await withTaskCancellationHandler(
                        operation: {
                            await withCheckedContinuation { continuation in
                                for task in tasks {
                                    Task<Void, Never> {
                                        _ = await task.result
                                        if await raceCoordinator.isFirstToCrossLine(task) {
                                            continuation.resume(returning: task)
                                        }
                                    }
                                }
                            }
                        },
                        onCancel: {
                            for task in tasks {
                                task.cancel()
                            }
                        }
                    )
                }()
                
                switch await firstTask.value {
                case .winner(let result, let iterator):
                    lastResult = result
                    lastEmission = Date()
                    self.base = iterator
                    
                    switch result {
                    case .success(let value):
                        // Base sequence has reached it's end.
                        if value == nil {
                            return nil
                        }
                    case .failure:
                        try result._rethrowError()
                    }
                case .sleep:
                    self.resultTask = resultTask
                    if let result = lastResult {
                        return try result._rethrowGet()
                    }
                }
            }
        }
    }
}

extension DebounceAsyncSequence.Iterator: Sendable
where
T.AsyncIterator: Sendable,
T.Element: Sendable {}

// MARK: Race result

extension DebounceAsyncSequence.Iterator {
    fileprivate enum RaceResult {
        case winner(Result<Element?, Error>, iterator: T.AsyncIterator)
        case sleep
    }
}

// MARK: Task race coordinator

fileprivate actor TaskRaceCoodinator<Success, Failure: Error> where Success: Sendable  {
    private var winner: Task<Success, Failure>?
    
    func isFirstToCrossLine(_ task: Task<Success, Failure>) -> Bool {
        guard self.winner == nil else { return false }
        self.winner = task
        return true
    }
}

// MARK: Debounce

extension AsyncSequence where AsyncIterator: Sendable, Element: Sendable {
    /// Emits elements only after a specified time interval elapses between emissions.
    ///
    /// Use the `debounce` operator to control the number of values and time between
    /// delivery of values from the base async sequence. This operator is useful to process bursty
    /// or high-volume async sequences where you need to reduce the number of elements emitted to a rate you specify.
    ///
    /// ```swift
    /// let sequence = AsyncStream<Int> { continuation in
    ///     continuation.yield(0)
    ///     try? await Task.sleep(seconds: 0.1)
    ///     continuation.yield(1)
    ///     try? await Task.sleep(seconds: 0.1)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.yield(4)
    ///     continuation.yield(5)
    ///     try? await Task.sleep(seconds: 0.1)
    ///     continuation.finish()
    /// }
    ///
    /// for element in try await sequence.debounce(for: 0.1) {
    ///     print(element)
    /// }
    ///
    /// // Prints:
    /// // 0
    /// // 1
    /// // 5
    /// ```
    /// - Parameters:
    ///   - base: The async sequence in which this sequence receives it's elements.
    ///   - dueTime: The amount of time the async sequence should wait before emitting an element.
    /// - Returns: A `DebounceAsyncSequence` instance.
    public func debounce(for dueTime: TimeInterval) -> DebounceAsyncSequence<Self> {
        .init(self, dueTime: dueTime)
    }
}
