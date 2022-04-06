import XCTest
@testable import Asynchrone


final class SharedAsyncSequenceTests: XCTestCase {
    private var values: [Int]!
    private var sequence: SharedAsyncSequence<SequenceAsyncSequence<[Int]>>!

    // MARK: Setup
    
    override func setUpWithError() throws {
        self.values = [0, 1, 2, 3, 4]
        self.sequence = values.async.shared()
    }

    // MARK: Tests
    
    func testSharedStreamShouldNotThrowExceptionAndReceiveAllValues() async throws {
        let taskCompleteExpectation = self.expectation(description: "Task complete")
        Task {
            let values = try await self.sequence.collect()
            XCTAssertEqual(values, [0, 1, 2, 3, 4])
            
            taskCompleteExpectation.fulfill()
        }
        
        let detachedTaskCompleteExpectation = self.expectation(description: "Detached task complete")
        Task.detached {
            let values = try await self.sequence.collect()
            XCTAssertEqual(values, [0, 1, 2, 3, 4])
            
            detachedTaskCompleteExpectation.fulfill()
        }
        
        let values = try await self.sequence.collect()
        XCTAssertEqual(values, [0, 1, 2, 3, 4])
        
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
