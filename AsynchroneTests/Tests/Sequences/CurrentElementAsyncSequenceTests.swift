import XCTest
@testable import Asynchrone


final class CurrentElementAsyncSequenceTests: XCTestCase {
    private var sequence: CurrentElementAsyncSequence<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = CurrentElementAsyncSequence(0)
    }
    
    // MARK: Tests
    
    func testCurrentElement() async {
        var element = await self.sequence.element
        XCTAssertEqual(element, 0)
        
        await self.sequence.yield(1)
        element = await self.sequence.element
        XCTAssertEqual(element, 1)
        
        await self.sequence.yield(2)
        await self.sequence.yield(3)
        await self.sequence.yield(4)
        element = await self.sequence.element
        XCTAssertEqual(element, 4)
    }
    
    func testSequence() async {
        await self.sequence.yield(1)
        await self.sequence.finish(with: 2)
        
        let values = await self.sequence.collect()
        XCTAssertEqual(values, [0, 1, 2])
    }
}
