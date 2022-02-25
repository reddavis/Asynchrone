import XCTest
@testable import Asynchrone


final class DelayAsyncSequenceTests: XCTestCase {
    private var stream: AsyncStream<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.stream = AsyncStream<Int> { continuation in
            continuation.yield(0)
            continuation.yield(1)
            continuation.yield(2)
            continuation.finish()
        }
    }

    // MARK: Tests
    
    func testDelay() async throws {
        var values: [TimestampedValue<Int>] = []
        
        for try await value in self.stream.delay(for: 0.5) {
            values.append(.init(value: value))
        }
        
        var difference = values[1].timestamp.timeIntervalSince(values[0].timestamp)
        XCTAssert(difference >= 0.5)
        
        difference = values[2].timestamp.timeIntervalSince(values[1].timestamp)
        XCTAssert(difference >= 0.5)
        
        XCTAssertEqual(values.map(\.value), [0, 1, 2])
    }
}


// MARK: OutputValue

fileprivate struct TimestampedValue<T> {
    var value: T
    var timestamp = Date()
}
