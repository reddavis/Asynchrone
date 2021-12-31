import XCTest
@testable import Asynchrone


final class ThrottleAsyncSequenceTests: XCTestCase {
    
    private var stream: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.stream = AsyncStream<Int> { continuation in
            continuation.yield(0)
            try? await Task.sleep(nanoseconds: 200_000_000)
            continuation.yield(1)
            try? await Task.sleep(nanoseconds: 200_000_000)
            continuation.yield(2)
            continuation.yield(3)
            continuation.yield(4)
            continuation.yield(5)
            continuation.finish()
        }
    }

    // MARK: Tests
    
    func testThrottle() async throws {
        let values = try await self.stream
            .throttle(for: 0.1, latest: false)
            .collect()
        XCTAssertEqual(values[0], 0)
        XCTAssertEqual(values[1], 1)
        XCTAssertEqual(values[2], 2)
        XCTAssertEqual(values[3], 3)
    }

    func testThrottleLatest() async throws {
        let values = try await self.stream
            .throttle(for: 0.1, latest: true)
            .collect()
        
        XCTAssertEqual(values[0], 0)
        XCTAssertEqual(values[1], 1)
        XCTAssertEqual(values[2], 2)
        XCTAssertEqual(values[3], 5)
    }
}
