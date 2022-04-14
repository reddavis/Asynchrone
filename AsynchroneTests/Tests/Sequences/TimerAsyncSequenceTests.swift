import XCTest
@testable import Asynchrone


final class TimerAsyncSequenceTests: XCTestCase {
    private var sequence: TimerAsyncSequence!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = .init(interval: 0.5)
    }

    // MARK: Tests
    
    func testTimerEmissions() async throws {
        var values: [Date] = []
        let start = Date()
        var end = Date()
        
        for await value in self.sequence {
            values.append(value)
            
            if values.count == 3 {
                end = Date()
                self.sequence.cancel()
            }
        }
        
        var difference = end.timeIntervalSince(start)
        XCTAssert(difference >= 1.5)
        
        difference = values[1].timeIntervalSince(values[0])
        XCTAssert(difference >= 0.5)
        
        difference = values[2].timeIntervalSince(values[1])
        XCTAssert(difference >= 0.5)
    }
}

