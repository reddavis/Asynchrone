import XCTest
@testable import Asynchrone


final class MergeAsyncSequenceTests: XCTestCase {
    private var streamA: AsyncStream<Int>!
    private var streamB: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.streamA = .init { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.yield(4)
            continuation.finish()
        }
        
        self.streamB = .init { continuation in
            continuation.yield(5)
            continuation.yield(6)
            continuation.yield(7)
            continuation.yield(8)
            continuation.yield(9)
            continuation.finish()
        }
    }
    
    // MARK: Tests
    
    func testMergingTwoSequences() async {
        let values = await self
            .streamA
            .merge(with: self.streamB)
            .collect()
        
        XCTAssertEqual(values.count, 9)
        XCTAssert(values.contains(1))
        XCTAssert(values.contains(2))
        XCTAssert(values.contains(3))
        XCTAssert(values.contains(4))
        XCTAssert(values.contains(5))
        XCTAssert(values.contains(6))
        XCTAssert(values.contains(7))
        XCTAssert(values.contains(8))
        XCTAssert(values.contains(9))
    }
}
