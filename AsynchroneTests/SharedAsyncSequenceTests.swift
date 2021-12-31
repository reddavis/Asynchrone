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
}
