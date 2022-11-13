import XCTest
@testable import Asynchrone

final class PassthroughAsyncSequenceTests: XCTestCase {
    private var sequence: PassthroughAsyncSequence<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = .init()
    }
    
    // MARK: Tests
    
    func testSequence() async throws {
        self.sequence.yield(0)
        self.sequence.yield(1)
        self.sequence.finish(with: 2)
        
        let values = await self.sequence.collect()
        XCTAssertEqual(values, [0, 1, 2])
    }
}
