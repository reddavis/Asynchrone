import XCTest
@testable import Asynchrone

final class DelayAsyncSequenceTests: XCTestCase {
    private var sequence: AnyAsyncSequenceable<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = [0, 1, 2].async.eraseToAnyAsyncSequenceable()
    }

    // MARK: Tests
    
    func testDelay() async throws {
        var values: [TimestampedValue<Int>] = []
        
        for try await value in self.sequence.delay(for: 0.5) {
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
