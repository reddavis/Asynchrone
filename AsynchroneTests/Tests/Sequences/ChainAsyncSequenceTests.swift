import XCTest
@testable import Asynchrone


final class ChainAsyncSequenceTests: XCTestCase {
    private var sequenceA: AnyAsyncSequenceable<Int>!
    private var sequenceB: AnyAsyncSequenceable<Int>!
    private var sequenceC: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequenceA = [1, 2, 3].async.eraseToAnyAsyncSequenceable()
        self.sequenceB = [4, 5, 6].async.eraseToAnyAsyncSequenceable()
        self.sequenceC = [7, 8, 9].async.eraseToAnyAsyncSequenceable()
    }
    
    // MARK: Tests
    
    func testChainingTwoSequences() async {
        let values = await self.sequenceA.chain(with: self.sequenceB).collect()
        XCTAssertEqual(values, [1, 2, 3, 4, 5, 6])
    }
    
    func testChainingThreeSequences() async {
        let values = await self.sequenceA
            .chain(with: self.sequenceB)
            .chain(with: self.sequenceC)
            .collect()
        
        XCTAssertEqual(values, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
}
