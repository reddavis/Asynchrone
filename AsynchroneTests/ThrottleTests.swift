//
//  ThrottleTests.swift
//  AsynchroneTests
//
//  Created by Michal Zaborowski on 2021-12-25.
//

import XCTest
@testable import Asynchrone
import Combine

final class ThrottleAsyncSequenceTests: XCTestCase {
    private var stream: AsyncStream<String>!

    override func setUpWithError() throws {
        let values = "abcd"
            .map { String(describing: $0) }
            .reduce([String]()) { values, next in
                let new = (values.last ?? "") + next
                return values + [new]
        }

        self.stream = .init { continuation in
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
    }

    // MARK: Tests

    func testThrottle() async throws {

        let stream = self
            .stream
            .throttle(0.25, latest: true)
            .eraseToAnyAsyncSequence()

        let valuesStream = await stream.collect()

        XCTAssertEqual(valuesStream[0], "a")
        XCTAssertEqual(valuesStream[1], "abc")
        XCTAssertEqual(valuesStream[2], "abcd")
    }
}
