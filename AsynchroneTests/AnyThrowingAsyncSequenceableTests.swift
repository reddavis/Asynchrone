import XCTest
@testable import Asynchrone


final class AnyThrowingAsyncSequenceableTests: XCTestCase {
    func testErasingFail() async throws {
        await XCTAssertAsyncThrowsError {
            _ = try await Fail<Int, TestError>(error: .init())
                .eraseToAnyThrowingAsyncSequenceable()
                .collect()
        }
    }
}
