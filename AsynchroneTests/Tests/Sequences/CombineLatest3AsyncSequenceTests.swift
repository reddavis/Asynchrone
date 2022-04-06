import XCTest
@testable import Asynchrone


final class CombineLatest3AsyncSequenceTests: XCTestCase {
    private var sequenceA: AnyAsyncSequenceable<Int>!
    private var sequenceB: AnyAsyncSequenceable<Int>!
    private var sequenceC: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequenceA = [1, 2, 3, 4].async.eraseToAnyAsyncSequenceable()
        self.sequenceB = [5, 6, 7, 8, 9].async.eraseToAnyAsyncSequenceable()
        self.sequenceC = [10, 11].async.eraseToAnyAsyncSequenceable()
    }
    
    // MARK: Tests
    
    func testCombiningTwoSequences() async {
        let values = await self
            .sequenceA
            .combineLatest(self.sequenceB, self.sequenceC)
            .collect()
        
        XCTAssertEqual(values.count, 5)
        XCTAssertEqual(values[0].0, 1)
        XCTAssertEqual(values[0].1, 5)
        XCTAssertEqual(values[0].2, 10)
        
        XCTAssertEqual(values[1].0, 2)
        XCTAssertEqual(values[1].1, 6)
        XCTAssertEqual(values[1].2, 11)
        
        XCTAssertEqual(values[2].0, 3)
        XCTAssertEqual(values[2].1, 7)
        XCTAssertEqual(values[2].2, 11)
        
        XCTAssertEqual(values[3].0, 4)
        XCTAssertEqual(values[3].1, 8)
        XCTAssertEqual(values[3].2, 11)
        
        XCTAssertEqual(values[4].0, 4)
        XCTAssertEqual(values[4].1, 9)
        XCTAssertEqual(values[4].2, 11)
    }
}
