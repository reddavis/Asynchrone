import XCTest
@testable import Asynchrone


final class FailTests: XCTestCase {
    
    func testErrorThrown() async {
        await XCTAssertAsyncThrowsError {
            _ = try await Fail<Int, TestError>(
                error: TestError()
            ).collect()
        }
    }
    
    func testErrorOnlyThrownOnce() async {
        let replacement = 0
        let values = await Fail<Int, TestError>(
            error: TestError()
        )
        .replaceError(with: replacement)
        .collect()
        
        XCTAssertEqual(values, [0])
    }
}
