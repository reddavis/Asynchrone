import XCTest
@testable import Asynchrone


final class Merge3AsyncSequenceTests: XCTestCase {
    private var sequenceA: AnyAsyncSequenceable<Int>!
    private var sequenceB: AnyAsyncSequenceable<Int>!
    private var sequenceC: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequenceA = [1, 4].async.eraseToAnyAsyncSequenceable()
        self.sequenceB = [2, 5, 7].async.eraseToAnyAsyncSequenceable()
        self.sequenceC = [3, 6].async.eraseToAnyAsyncSequenceable()
    }
    
    // MARK: Tests
    
    func testMergingThreeSequences() async throws {
        let values = try await self
            .sequenceA
            .merge(with: self.sequenceB, self.sequenceC)
            .collect()
        
        XCTAssertEqual(values.count, 7)
        XCTAssert(values.contains(1))
        XCTAssert(values.contains(2))
        XCTAssert(values.contains(3))
        XCTAssert(values.contains(4))
        XCTAssert(values.contains(5))
        XCTAssert(values.contains(6))
        XCTAssert(values.contains(7))
    }
}
