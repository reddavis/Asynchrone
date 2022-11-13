import XCTest
@testable import Asynchrone

final class AsyncSequenceTests: XCTestCase {
    private var sequence: AsyncStream<Int>!
     
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
    }
    
    // MARK: Assign
    
    private var assignableValue: Int = 0
    
    func testAssign() async {
        self.sequence.assign(to: \.assignableValue, on: self)
        await XCTAssertEventuallyEqual(self.assignableValue, 3)
    }
    
    // MARK: First
    
    func testFirst() async {
        let element = await self.sequence.first()
        XCTAssertEqual(element, 1)
    }
    
    // MARK: Last
    
    func testLast() async {
        let element = await self.sequence.last()
        XCTAssertEqual(element, 3)
    }
    
    // MARK: Collect
    
    func testCollect() async {
        let values = await self.sequence.collect()
        XCTAssertEqual(values, [1, 2, 3])
    }
    
    func testCollectWithLimit() async {
        let values = await self.sequence.collect(2)
        XCTAssertEqual(values, [1, 2])
    }
    
    // MARK: Sink
    
    func testSink() async {
        let store = Store<Int>()
        self.sequence.sink { await store.append($0) }
        
        await XCTAssertEventuallyEqual(
            { await store.values },
            { [1, 2, 3] }
        )
    }
    
    func testSinkWithFinishedCompletion() async {
        let completionExpectation = self.expectation(description: "Completion called")
        let store = Store<Int>()
        self.sequence.sink(
            receiveValue: { await store.append($0) },
            receiveCompletion: {
                switch $0 {
                case .failure(let error):
                    XCTFail("Invalid completion case: Failure \(error)")
                case .finished:
                    completionExpectation.fulfill()
                }
            }
        )
        
        await self.waitForExpectations(timeout: 5.0, handler: nil)
        
        let values = await store.values
        XCTAssertEqual(values, [1, 2, 3])
    }
    
    func testSinkWithFailedCompletion() async {
        let completionExpectation = self.expectation(description: "Completion called")
        let sequence = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish(throwing: TestError())
        }
        
        let store = Store<Int>()
        sequence.sink(
            receiveValue: { await store.append($0) },
            receiveCompletion: {
                switch $0 {
                case .failure:
                    completionExpectation.fulfill()
                case .finished:
                    XCTFail("Invalid completion case: Finished")
                }
            }
        )
        
        await self.waitForExpectations(timeout: 5.0, handler: nil)
        
        let values = await store.values
        XCTAssertEqual(values, [1, 2, 3])
    }
    
    func testSinkWithCancellation() async {
        let completionExpectation = self.expectation(description: "Completion called")
        let sequence = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(1)
        }
        
        let store = Store<Int>()
        let task = sequence.sink(
            receiveValue: { await store.append($0) },
            receiveCompletion: {
                switch $0 {
                case .failure(let error) where error is CancellationError:
                    completionExpectation.fulfill()
                case .failure(let error):
                    XCTFail("Invalid failure error: \(error)")
                case .finished:
                    XCTFail("Invalid completion case: Finished")
                }
            }
        )
        
        task.cancel()
        await self.waitForExpectations(timeout: 5.0, handler: nil)
        
        let values = await store.values
        XCTAssertEqual(values, [1])
    }
}

// MARK: Store

fileprivate actor Store<T> {
    var values: [T] = []
    
    fileprivate func append(_ newElement: T) {
        self.values.append(newElement)
    }
}
