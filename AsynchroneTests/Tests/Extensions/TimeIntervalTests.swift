import XCTest
@testable import Asynchrone


final class TimeIntervalTests: XCTestCase {
    func testAsNanoseconds() {
        XCTAssertEqual(1.asNanoseconds, 1_000_000_000)
        XCTAssertEqual(1.5.asNanoseconds, 1_500_000_000)
    }
}
