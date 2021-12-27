//
//  AnyAsyncSequenceTests.swift
//  AsynchroneTests
//
//  Created by Michal Zaborowski on 2021-12-27.
//

import XCTest
@testable import Asynchrone

 final class AnyAsyncSequenceTests: XCTestCase {
     func testErasingJust() async throws {
         let values = await Just(1)
             .eraseToAnyAsyncSequence()
             .collect()
         XCTAssertEqual(values, [1])
     }
 }
