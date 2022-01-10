import XCTest
@testable import Asynchrone


final class ThrottleAsyncSequenceTests: XCTestCase {
    
    private var stream: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.stream = AsyncStream<Int> { continuation in
            continuation.yield(0)
            try? await Task.sleep(nanoseconds: 100_000_000)
            continuation.yield(1)
            try? await Task.sleep(nanoseconds: 100_000_000)
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
            .throttle(for: 0.05, latest: false)
            .collect()
        
        XCTAssertEqual(values, [0, 1, 2, 3])
    }

    func testThrottleLatest() async throws {
        let values = try await self.stream
            .throttle(for: 0.05, latest: true)
            .collect()
        
        XCTAssertEqual(values, [0, 1, 2, 5])
    }
    
    func testThrottleWithNoValues() async throws {
        let values = try await AsyncStream<Int> {
            $0.finish()
        }
        .throttle(for: 0.05, latest: true)
        .collect()
        
        XCTAssert(values.isEmpty)
    }
    
    func testThrottleWithOneValue() async throws {
        let values = try await Just(0)
            .throttle(for: 0.05, latest: true)
            .collect()
        
        XCTAssertEqual(values, [0])
    }
}
