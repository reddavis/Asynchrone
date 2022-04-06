import XCTest
@testable import Asynchrone


final class SequenceAsyncSequenceTests: XCTestCase {
    func testCreatingAsyncSequence() async {
        let array = [0, 1, 2, 3]
        let sequence = array.async
        let values = await sequence.collect()
        
        XCTAssertEqual(values, array)
    }
}
