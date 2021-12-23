import XCTest
@testable import Asynchrone


final class FailTests: XCTestCase {
    func testEmittedElements() async {
        await XCTAssertAsyncThrowsError {
            _ = try await Fail<Int, TestError>(
                error: TestError()
            ).collect()
        }
    }
}



// MARK: Test error

fileprivate struct TestError: Error { }
