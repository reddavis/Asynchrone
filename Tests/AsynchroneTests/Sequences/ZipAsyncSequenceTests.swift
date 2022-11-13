import XCTest
@testable import Asynchrone

final class ZipAsyncSequenceTests: XCTestCase {
    private var sequenceA: AnyAsyncSequenceable<Int>!
    private var sequenceB: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequenceA = [1, 2].async.eraseToAnyAsyncSequenceable()
        self.sequenceB = [5, 6, 7].async.eraseToAnyAsyncSequenceable()
    }
    
    // MARK: Tests
    
    func testZippingTwoSequences() async {
        let values = await self
            .sequenceA
            .zip(self.sequenceB)
            .collect()
        
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0].0, 1)
        XCTAssertEqual(values[0].1, 5)
        
        XCTAssertEqual(values[1].0, 2)
        XCTAssertEqual(values[1].1, 6)
    }
}
