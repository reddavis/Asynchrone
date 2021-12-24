import XCTest
@testable import Asynchrone


final class AnyThrowingAsyncSequenceableTests: XCTestCase {
    func testErasingFail() async throws {
        await XCTAssertAsyncThrowsError {
            _ = try await Fail<Int, TestError>(error: TestError.a)
                .eraseToAnyThrowingAsyncSequenceable()
                .collect()
        }
    }
}



// MARK: Error

fileprivate enum TestError: Error {
    case a
}
