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
    private var stream: AsyncStream<(TimeInterval, String)>!

    override func setUpWithError() throws {
        let values = "abcdefghijklmnopqrstuvwxyz"
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
                            continuation.yield((delay, value))
                            continuation.finish()
                        } else {
                            continuation.yield((delay, value))
                        }
                    }
                }
            }
        }
    }

    // MARK: Tests

    func testThrottle() async throws {

        let valuesStream = self
            .stream
            .throttle(0.1, latest: false)

        for await value in valuesStream {
            print("Stream: \(value.0) \(value.1)")
        }
        
        _ = valuesStream
//        stream.

    }

    func test2() {
        let values = "abcdefghijklmnopqrstuvwxyz"
            .map { String(describing: $0) }
            .reduce([String]()) { values, next in
                let new = (values.last ?? "") + next
                return values + [new]
        }

        // 2
        let subject = PassthroughSubject<(Double, String), Never>()

        // 3
        values.enumerated().forEach { i, value in
            let delay = TimeInterval(i) / 10.0

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                subject.send((delay, value))
            }
        }

        let exp = expectation(description: "asd")



        let throttleLatestSubscription = subject
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: false)
            .sink(receiveValue: { print("Combine: \($0.0) \($0.1)") })

        wait(for: [exp], timeout: 5.0)

        _ = throttleLatestSubscription
    }
}
