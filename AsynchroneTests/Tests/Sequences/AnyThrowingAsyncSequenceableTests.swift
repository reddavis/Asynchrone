import XCTest
@testable import Asynchrone


final class AnyThrowingAsyncSequenceableTests: XCTestCase {
    func testErasingFail() async throws {
        await XCTAsyncAssertThrow {
            _ = try await Fail<Int, TestError>(error: .init())
                .eraseToAnyThrowingAsyncSequenceable()
                .collect()
        }
    }
}
