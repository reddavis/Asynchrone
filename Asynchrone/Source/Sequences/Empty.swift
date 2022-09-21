/// An asynchronous sequence that only emits the provided value once.
///
/// ```swift
/// Empty<Int>().sink(
///     receiveValue: { print($0) },
///     receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Finished")
///         case .failure:
///             print("Failed")
///         }
///     }
/// )
///
/// // Prints:
/// // Finished
/// ```
public struct Empty<Element>: AsyncSequence, Sendable {
    private let completeImmediately: Bool
    
    // MARK: Initialization
    
    /// Creates an empty async sequence.
    ///
    /// - Parameter completeImmediately: A Boolean value that indicates whether
    /// the async sequence should immediately finish.
    public init(completeImmediately: Bool = true) {
        self.completeImmediately = completeImmediately
    }
    
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Self {
        .init(completeImmediately: self.completeImmediately)
    }
}

// MARK: AsyncIteratorProtocol

extension Empty: AsyncIteratorProtocol {
    /// Produces the next element in the sequence.
    ///
    /// Because this is an empty sequence, this will always be nil.
    ///
    /// - Returns: `nil` as this is an empty sequence.
    public mutating func next() async -> Element? {
        if !self.completeImmediately {
            try? await Task.sleep(seconds: 999_999_999)
        }

        return nil
    }
}
