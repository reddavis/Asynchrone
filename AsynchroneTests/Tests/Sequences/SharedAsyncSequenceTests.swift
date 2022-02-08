import XCTest
@testable import Asynchrone


final class SharedAsyncSequenceTests: XCTestCase {
    private var stream: SharedAsyncSequence<AsyncStream<String>>!

    // MARK: Setup
    
    override func setUpWithError() throws {
        let values = [
            "a",
            "ab",
            "abc",
            "abcd"
        ]
        
        self.stream = AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
        .shared()
    }

    // MARK: Tests
    
    func testSharedStreamShouldNotThrowExceptionAndReceiveAllValues() async throws {
        Task {
            let values = try await self.stream.collect()
            XCTAssertEqual(values[0], "a")
            XCTAssertEqual(values[1], "ab")
            XCTAssertEqual(values[2], "abc")
            XCTAssertEqual(values[3], "abcd")
        }

        Task.detached {
            let values = try await self.stream.collect()
            XCTAssertEqual(values[0], "a")
            XCTAssertEqual(values[1], "ab")
            XCTAssertEqual(values[2], "abc")
            XCTAssertEqual(values[3], "abcd")
        }
        
        let values = try await self.stream.collect()
        XCTAssertEqual(values.count, 4)
        XCTAssertEqual(values[0], "a")
        XCTAssertEqual(values[1], "ab")
        XCTAssertEqual(values[2], "abc")
        XCTAssertEqual(values[3], "abcd")
    }
    
    func testAccessingBaseCurrentElementAsyncSequenceFunctionality() async throws {
        let valueA = "a"
        let valueB = "b"
        let valueC = "c"
        
        let stream = CurrentElementAsyncSequence(valueA).shared()
        
        // Yield new value
        await stream.yield(valueB)
        await stream.finish(with: valueC)
        
        let values = try await stream.collect()
        XCTAssertEqual(values[0], "a")
        XCTAssertEqual(values[1], "b")
        XCTAssertEqual(values[2], "c")
        XCTAssertEqual(values.count, 3)
        
        let currentValue = await stream.element()
        XCTAssertEqual(currentValue, valueC)
    }
    
    func testAccessingBasePassthroughAsyncSequenceFunctionality() async throws {
        let valueA = "a"
        let valueB = "b"
        
        let stream = PassthroughAsyncSequence<String>().shared()
        
        // Yield new value
        stream.yield(valueA)
        stream.finish(with: valueB)
        
        let values = try await stream.collect()
        XCTAssertEqual(values[0], "a")
        XCTAssertEqual(values[1], "b")
        XCTAssertEqual(values.count, 2)
    }
}
