import XCTest
@testable import Asynchrone


final class AsyncStreamTests: XCTestCase {
    
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
    
    // MARK: Just
    
    func testJust() async {
        let stream = AsyncStream.just(1)
        
        var values: [Int] = []
        for await value in stream {
            values.append(value)
        }
        
        XCTAssertEqual(values, [1])
    }
}
