import XCTest
@testable import Asynchrone

class CatchErrorTests: XCTestCase {
    func testErrorCaught() async {
        let replacement = 0
        
        let values = await Fail<Int, TestError>(
            error: TestError()
        )
        .catch { _ in
            Just(replacement)
        }
        .collect()
        
        XCTAssertEqual(values, [replacement])
    }
}
