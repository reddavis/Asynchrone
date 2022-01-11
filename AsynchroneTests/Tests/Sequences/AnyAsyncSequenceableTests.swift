import XCTest
@testable import Asynchrone


final class AnyAsyncSequenceableTests: XCTestCase {
    func testErasingJust() async throws {
        let values = await Just(1)
            .eraseToAnyAsyncSequenceable()
            .collect()
        XCTAssertEqual(values, [1])
    }
}
