import XCTest
@testable import Asynchrone


final class Merge3AsyncSequenceTests: XCTestCase {
    private var streamA: AsyncStream<Int>!
    private var streamB: AsyncStream<Int>!
    private var streamC: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.streamA = .init { continuation in
            continuation.yield(1)
            continuation.yield(4)
            continuation.finish()
        }
        
        self.streamB = .init { continuation in
            continuation.yield(2)
            continuation.yield(5)
            continuation.yield(7)
            continuation.finish()
        }
        
        self.streamC = .init { continuation in
            continuation.yield(3)
            continuation.yield(6)
            continuation.finish()
        }
    }
    
    // MARK: Tests
    
    func testMergingThreeSequences() async throws {
        let values = try await self
            .streamA
            .merge(with: self.streamB, self.streamC)
            .collect()
        
        XCTAssertEqual(values.count, 7)
        XCTAssert(values.contains(1))
        XCTAssert(values.contains(2))
        XCTAssert(values.contains(3))
        XCTAssert(values.contains(4))
        XCTAssert(values.contains(5))
        XCTAssert(values.contains(6))
        XCTAssert(values.contains(7))
    }
}
