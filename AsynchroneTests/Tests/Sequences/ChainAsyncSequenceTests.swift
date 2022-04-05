import XCTest
@testable import Asynchrone


final class ChainAsyncSequenceTests: XCTestCase {
    private var sequenceA: AsyncStream<Int>!
    private var sequenceB: AsyncStream<Int>!
    private var sequenceC: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequenceA = .init { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        
        self.sequenceB = .init { continuation in
            continuation.yield(4)
            continuation.yield(5)
            continuation.yield(6)
            continuation.finish()
        }
        
        self.sequenceC = .init { continuation in
            continuation.yield(7)
            continuation.yield(8)
            continuation.yield(9)
            continuation.finish()
        }
    }
    
    // MARK: Tests
    
    func testChainingTwoSequences() async {
        let values = await (self.sequenceA <> self.sequenceB).collect()
        XCTAssertEqual(values, [1, 2, 3, 4, 5, 6])
    }
    
    func testChainingThreeSequences() async {
        let values = await (
            self.sequenceA <>
            self.sequenceB <>
            self.sequenceC
        ).collect()
        
        XCTAssertEqual(values, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
}
