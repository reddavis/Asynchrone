extension AsyncSequence {
    
    /// Assigns each element from an async sequence to a property on an object.
    ///
    /// ```swift
    /// class MyClass {
    ///     var value: Int = 0 {
    ///         didSet { print("Set to \(self.value)") }
    ///     }
    /// }
    ///
    ///
    /// let sequence = AsyncStream<Int> { continuation in
    ///     continuation.yield(1)
    ///     continuation.yield(2)
    ///     continuation.yield(3)
    ///     continuation.finish()
    /// }
    ///
    /// let object = MyClass()
    /// sequence.assign(to: \.value, on: object)
    ///
    /// // Prints:
    /// // Set to 1
    /// // Set to 2
    /// // Set to 3
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to indicate the property to be assign.
    ///   - object: The object that contains the property.
    /// - Returns: A `Task<Void, Error>`. It is not required to keep reference to the task,
    /// but it does give the ability to cancel the assign by calling `cancel()`.
    @discardableResult
    public func assign<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Element>,
        on object: Root
    ) rethrows -> Task<Void, Error> {
        Task {
            for try await element in self {
                object[keyPath: keyPath] = element
            }
        }
    }
    
    /// The first element of the sequence, if there is one.
    public func first() async rethrows -> Element? {
        try await self.first { _ in
            true
        }
    }
    
    /// Collect elements from a sequence.
    ///
    /// ```swift
    /// // Collect all elements.
    /// var values = await self.sequence.collect()
    /// print(values)
    ///
    /// // Prints:
    /// // [1, 2, 3]
    ///
    /// // Collect only 2 elements.
    /// values = await self.sequence.collect(2)
    /// print(values)
    ///
    /// // Prints:
    /// // [1, 2]
    /// ```
    ///
    /// - Parameter numberOfElements: The number of elements to collect. By default
    /// this is `nil` which indicates all elements will be collected. If the number of elements
    /// in the sequence is less than the number of elements requested, then all the elements will
    /// be collected.
    /// - Returns: Returns: An array of all elements.
    public func collect(_ numberOfElements: Int? = .none) async rethrows -> [Element] {
        var results: [Element] = []
        for try await element in self {
            results.append(element)
            
            if let numberOfElements = numberOfElements,
               results.count >= numberOfElements {
               break
            }
        }
        
        return results
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
    public func sink(_ receiveValue: @escaping (Element) async -> Void) -> Task<Void, Error> {
        Task {
            for try await element in self {
                await receiveValue(element)
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
        receiveValue: @escaping (Element) async -> Void,
        receiveCompletion: @escaping (AsyncSequenceCompletion<Error>) async -> Void
    ) -> Task<Void, Never> {
        Task {
            do {
                for try await element in self {
                    await receiveValue(element)
                }
                
                await receiveCompletion(.finished)
            } catch {
                await receiveCompletion(.failure(error))
            }
        }
    }
}
