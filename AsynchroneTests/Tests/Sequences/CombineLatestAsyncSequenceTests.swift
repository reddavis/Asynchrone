import XCTest
@testable import Asynchrone


final class CombineLatestAsyncSequenceTests: XCTestCase {
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
    
    func testCombiningTwoSequences() async {
        let values = await self
            .streamA
            .combineLatest(self.streamB)
            .collect()
        
        XCTAssertEqual(values.count, 5)
        XCTAssertEqual(values[0].0, 1)
        XCTAssertEqual(values[0].1, 5)
        
        XCTAssertEqual(values[1].0, 2)
        XCTAssertEqual(values[1].1, 6)
        
        XCTAssertEqual(values[2].0, 3)
        XCTAssertEqual(values[2].1, 7)
        
        XCTAssertEqual(values[3].0, 4)
        XCTAssertEqual(values[3].1, 8)
        
        XCTAssertEqual(values[4].0, 4)
        XCTAssertEqual(values[4].1, 9)
    }
}
