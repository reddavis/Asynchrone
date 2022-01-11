import Foundation


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
}
