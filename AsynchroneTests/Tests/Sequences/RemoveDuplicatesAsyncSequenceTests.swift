import XCTest
@testable import Asynchrone


final class RemoveDuplicatesAsyncSequenceTests: XCTestCase {
    private var sequence: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = [1, 1, 2, 2, 3, 3, 1].async.eraseToAnyAsyncSequenceable()
    }
    
    // MARK: Tests
    
    func testDuplicatesRemoved() async {
        let values = await self
            .sequence
            .removeDuplicates()
            .collect()
        
        XCTAssertEqual(values, [1, 2, 3, 1])
    }
    
    func testRemovingDuplicatesWithPredicate() async {
        let values = await self
            .sequence
            .removeDuplicates { previous, current in
                previous >= current
            }
            .collect()
        
        XCTAssertEqual(values, [1, 2, 3])
    }
}
