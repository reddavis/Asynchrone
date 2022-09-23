//
//  AsyncStreamTests.swift
//
//
//  Created by Tim Sakhuja on 9/22/22.
//

import XCTest
@testable import Asynchrone

final class AsyncStreamTests: XCTestCase {
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

    // MARK: Cancellation Propagation
    func testCancellationPropagation() async {
        let task = Task {
            AsyncStream<Int> { continuation in
                for await event in self.sequence {
                    continuation.yield(event)
                }

                XCTAssertTrue(Task.isCancelled)
            }
        }

        task.cancel()
    }
}
