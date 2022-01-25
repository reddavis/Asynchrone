extension AsyncSequence {
    /// The first element of the sequence, if there is one.
    public func first() async rethrows -> Element? {
        try await self.first { _ in
            true
        }
    }
    
    /// Collect all elements from a sequence.
    /// - Returns: An array of all elements.
    public func collect() async rethrows -> [Element] {
        try await self.reduce(into: [Element]()) { result, element in
            result.append(element)
        }
    }
    
    /// Consume the async sequence and pass the element's to a closure.
    ///
    /// ```swift
    /// let sequence = .init { continuation in
    ///     continuation.yield(1)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.finish()
    /// }
    ///
    /// sequence.sink { print($0) }
    ///
    /// // Prints:
    /// // 1
    /// // 2
    /// // 3
    /// ```
    /// - Parameter receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A task instance.
    @discardableResult
    public func sink(_ receiveValue: @escaping (Element) -> Void) -> Task<Void, Error> {
        Task {
            for try await element in self {
                receiveValue(element)
            }
        }
    }
    
    /// Consume the async sequence and pass the element's and it's completion
    /// state to two closures.
    ///
    /// ```swift
    /// let sequence = .init { continuation in
    ///     continuation.yield(1)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.finish(throwing: TestError())
    /// }
    ///
    /// sequence.sink(
    ///     receiveValue: { print("Value: \($0)") },
    ///     receiveCompletion: { print("Complete: \($0)") }
    /// )
    ///
    /// // Prints:
    /// // Value: 1
    /// // Value: 2
    /// // Value: 3
    /// // Complete: failure(TestError())
    /// ```
    /// - Parameters:
    ///   - receiveValue: The closure to execute on receipt of a value.
    ///   - receiveCompletion: The closure to execute on completion.
    /// - Returns: A task instance.
    @discardableResult
    public func sink(
        receiveValue: @escaping (Element) -> Void,
        receiveCompletion: @escaping (AsyncSequenceCompletion<Error>) -> Void
    ) -> Task<Void, Never> {
        Task {
            do {
                for try await element in self {
                    receiveValue(element)
                }
                
                receiveCompletion(.finished)
            } catch {
                receiveCompletion(.failure(error))
            }
        }
    }
}
