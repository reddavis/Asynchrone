//
//  AnyThrowingAsyncSequenceTests.swift
//  AsynchroneTests
//
//  Created by Michal Zaborowski on 2021-12-27.
//

import XCTest
@testable import Asynchrone

 final class AnyThrowingAsyncSequenceTests: XCTestCase {
     func testErasingFail() async throws {
         await XCTAssertAsyncThrowsError {
             _ = try await Fail<Int, TestError>(error: TestError.a)
                 .eraseToAnyAsyncThrowingSequence()
                 .collect()
         }
     }
 }

 // MARK: Error

 fileprivate enum TestError: Error {
     case a
 }
