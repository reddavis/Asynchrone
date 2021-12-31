import XCTest
@testable import Asynchrone


final class ThrottleAsyncSequenceTests: XCTestCase {
    
    private var stream: AsyncStream<String>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        let values = "abcd"
            .map { String(describing: $0) }
            .reduce([String]()) { values, next in
                let new = (values.last ?? "") + next
                return values + [new]
        }

        self.stream = .init { continuation in
            values.enumerated().forEach { i, value in
                let delay = TimeInterval(i) / 10.0

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if i == values.count - 1 {
                        continuation.yield(value)
                        continuation.finish()
                    } else {
                        continuation.yield(value)
                    }
                }
            }
        }
    }

    // MARK: Tests

    func testThrottleLatest() async throws {
        let stream = self
            .stream
            .throttle(for: 0.25, latest: true)

        let valuesStream = try await stream.collect()

        XCTAssertEqual(valuesStream[0], "a")
        XCTAssertEqual(valuesStream[1], "abc")
        XCTAssertEqual(valuesStream[2], "abcd")
    }

    func testThrottle() async throws {
        let stream = self
            .stream
            .throttle(for: 0.25, latest: false)

        let valuesStream = try await stream.collect()

        XCTAssertEqual(valuesStream[0], "a")
        XCTAssertEqual(valuesStream[1], "ab")
        XCTAssertEqual(valuesStream[2], "abcd")
    }

    func testThrowingThrottle() async throws {
        await XCTAssertAsyncThrowsError {
            _ = try await Fail<Int, TestError>(error: TestError.a)
                .throttle(for: 0.2, latest: true)
                .collect()
        }
    }
}



// MARK: Error

fileprivate enum TestError: Error {
    case a
}
