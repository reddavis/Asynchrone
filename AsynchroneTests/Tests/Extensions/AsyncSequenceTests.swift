import XCTest
@testable import Asynchrone


final class AsyncSequenceTests: XCTestCase {
    
    // Private
    private var stream: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.stream = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
    }
    
    // MARK: First
    
    func testFirst() async {
        let firstValue = await self.stream.first()
        XCTAssertEqual(firstValue, 1)
    }
    
    // MARK: Collect
    
    func testCollect() async {
        let values = await self.stream.collect()
        XCTAssertEqual(values, [1, 2, 3])
    }
}
