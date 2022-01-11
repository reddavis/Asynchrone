import XCTest
@testable import Asynchrone


final class DebounceAsyncSequenceTests: XCTestCase {
    
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
    
    func testDebounce() async throws {
        let values = try await self.stream
            .debounce(for: 0.1)
            .collect()
        
        XCTAssertEqual(values, [0, 1, 5])
    }
    
    func testDebounceWithNoValues() async throws {
        let values = try await AsyncStream<Int> {
            $0.finish()
        }
        .debounce(for: 0.1)
        .collect()
        
        XCTAssert(values.isEmpty)
    }
    
    func testDebounceWithOneValue() async throws {
        let values = try await Just(0)
            .debounce(for: 0.1)
            .collect()
        
        XCTAssertEqual(values, [0])
    }
}
