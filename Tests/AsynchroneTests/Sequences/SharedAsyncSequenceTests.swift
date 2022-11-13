import XCTest
@testable import Asynchrone

final class SharedAsyncSequenceTests: XCTestCase {
    private var sequence: SharedAsyncSequence<PassthroughAsyncSequence<Int>>!

    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = PassthroughAsyncSequence<Int>().shared()
    }

    // MARK: Tests

    func testSharedStreamShouldNotThrowExceptionAndReceiveAllValues() async {
        let taskCompleteExpectation = self.expectation(description: "Task complete")
        Task {
            let values = try await self.sequence.collect()
            XCTAssertEqual(values, [0, 1, 2, 3])
            taskCompleteExpectation.fulfill()
        }
        
        let detachedTaskCompleteExpectation = self.expectation(description: "Detached task complete")
        Task.detached {
            let values = try await self.sequence.collect()
            XCTAssertEqual(values, [0, 1, 2, 3])
            detachedTaskCompleteExpectation.fulfill()
        }
        
        Task.detached {
            try? await Task.sleep(seconds: 0.5)
            self.sequence.yield(0)
            self.sequence.yield(1)
            self.sequence.yield(2)
            self.sequence.finish(with: 3)
        }
        
        await self.waitForExpectations(timeout: 5)
    }
    
    func testAccessingBaseCurrentElementAsyncSequenceFunctionality() async throws {
        let valueA = 0
        let valueB = 1
        let valueC = 2
        
        let sequence = CurrentElementAsyncSequence(valueA).shared()
        
        // Yield new value
        await sequence.yield(valueB)
        await sequence.finish(with: valueC)
        
        let values = try await sequence.collect()
        XCTAssertEqual(values, [0, 1, 2])
        
        let currentValue = await sequence.element()
        XCTAssertEqual(currentValue, valueC)
    }
    
    func testAccessingBasePassthroughAsyncSequenceFunctionality() async throws {
        let valueA = 0
        let valueB = 1
        
        let sequence = PassthroughAsyncSequence<Int>().shared()
        
        // Yield new value
        sequence.yield(valueA)
        sequence.finish(with: valueB)
        
        let values = try await sequence.collect()
        XCTAssertEqual(values, [0, 1])
    }
}
