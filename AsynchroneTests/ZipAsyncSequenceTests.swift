import XCTest
@testable import Asynchrone


final class ZipAsyncSequenceTests: XCTestCase {
    private var streamA: AsyncStream<Int>!
    private var streamB: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.streamA = .init { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
        
        self.streamB = .init { continuation in
            continuation.yield(5)
            continuation.yield(6)
            continuation.yield(7)
            continuation.finish()
        }
    }
    
    // MARK: Tests
    
    func testZippingTwoSequences() async {
        let values = await self
            .streamA
            .zip(self.streamB)
            .collect()
        
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0].0, 1)
        XCTAssertEqual(values[0].1, 5)
        
        XCTAssertEqual(values[1].0, 2)
        XCTAssertEqual(values[1].1, 6)
    }
}
