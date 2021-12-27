//
//  SharedAsyncSequenceTests.swift
//  AsynchroneTests
//
//  Created by Michal Zaborowski on 2021-12-27.
//

import XCTest
@testable import Asynchrone

final class SharedAsyncSequenceTests: XCTestCase {
    private var stream: SharedAsyncSequence<AsyncStream<String>>!

    override func setUpWithError() throws {
        let values = "abcd"
            .map { String(describing: $0) }
            .reduce([String]()) { values, next in
                let new = (values.last ?? "") + next
                return values + [new]
        }

        let stream = AsyncStream<String> { continuation in
            Task {
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

        self.stream = stream.shared()
    }

    func testSharedStreamShouldNotThrowExceptionAndReceiveAllValues() async throws {

        let valuesStream = try await self.stream
            .throttle(0.25, latest: true)
            .collect()

        Task {
            let valuesStream = try await self.stream.collect()
            XCTAssertEqual(valuesStream[0], "a")
            XCTAssertEqual(valuesStream[1], "ab")
            XCTAssertEqual(valuesStream[2], "abc")
            XCTAssertEqual(valuesStream[3], "abcd")
        }

        Task {
            var valuesStream: [String] = []
            for try await value in self.stream {
                valuesStream.append(value)
            }
            XCTAssertEqual(valuesStream[0], "a")
            XCTAssertEqual(valuesStream[1], "ab")
            XCTAssertEqual(valuesStream[2], "abc")
            XCTAssertEqual(valuesStream[3], "abcd")
        }

        XCTAssertEqual(valuesStream[0], "a")
        XCTAssertEqual(valuesStream[1], "abc")
        XCTAssertEqual(valuesStream[2], "abcd")
    }
}
