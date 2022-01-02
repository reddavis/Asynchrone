import XCTest
@testable import Asynchrone


final class ReplaceErrorTests: XCTestCase {
    
    func testErrorReplaced() async {
        let replacement = 0
        
        let values = await Fail<Int, TestError>(
            error: TestError()
        )
        .replaceError(with: replacement)
        .collect()
        
        XCTAssertEqual(values, [replacement])
    }
}
