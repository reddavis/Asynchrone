import XCTest
@testable import Asynchrone

final class MergeAsyncSequenceTests: XCTestCase {
    private var sequenceA: AnyAsyncSequenceable<Int>!
    private var sequenceB: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequenceA = [1, 2, 3, 4].async.eraseToAnyAsyncSequenceable()
        self.sequenceB = [5, 6, 7, 8, 9].async.eraseToAnyAsyncSequenceable()
    }
    
    // MARK: Tests
    
    func testMergingTwoSequences() async {
        let values = await self
            .sequenceA
            .merge(with: self.sequenceB)
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
