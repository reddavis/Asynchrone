import XCTest
@testable import Asynchrone


final class JustTests: XCTestCase {
    func testEmittedElements() async {
        let values = await Just(1).collect()
        XCTAssertEqual(values, [1])
    }
}
