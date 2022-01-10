import XCTest
@testable import Asynchrone


final class RemoveDuplicatesAsyncSequenceTests: XCTestCase {
    private var stream: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.stream = .init { continuation in
            continuation.yield(1)
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(2)
            continuation.yield(3)
            continuation.yield(3)
            continuation.yield(1)
            continuation.finish()
        }
    }
    
    // MARK: Tests
    
    func testDuplicatesRemoved() async {
        let values = await self
            .stream
            .removeDuplicates()
            .collect()
        
        XCTAssertEqual(values, [1, 2, 3, 1])
    }
    
    func testRemovingDuplicatesWithPredicate() async {
        let values = await self
            .stream
            .removeDuplicates { previous, current in
                previous >= current
            }
            .collect()
        
        XCTAssertEqual(values, [1, 2, 3])
    }
}
