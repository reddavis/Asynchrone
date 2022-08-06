import XCTest

/// Asserts that an async expression is not `nil`, and returns its unwrapped value.
///
/// Generates a failure when `expression == nil`.
///
/// - Parameters:
///   - expression: An expression of type `T?` to compare against `nil`.
///   Its type will determine the type of the returned value.
///   - message: An optional description of the failure.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
/// - Returns: A value of type `T`, the result of evaluating and unwrapping the given `expression`.
/// - Throws: An error when `expression == nil`. It will also rethrow any error thrown while evaluating the given expression.
func XCTAsyncUnwrap<T>(
    _ expression: () async throws -> T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws -> T {
    let value = try await expression()
    return try XCTUnwrap(value, message(), file: file, line: line)
}

/// Assert two expressions are eventually equal.
/// - Parameters:
///   - expressionA: Expression A
///   - expressionB: Expression B
///   - timeout: Time to wait for store state changes. Defaults to `5`
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAssertEventuallyEqual<T: Equatable>(
    _ expressionA: @autoclosure @escaping () -> T?,
    _ expressionB: @autoclosure @escaping () -> T?,
    timeout: TimeInterval = 5.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let timeoutDate = Date(timeIntervalSinceNow: timeout)
            
    while true {
        let resultA = expressionA()
        let resultB = expressionB()
        
        switch resultA == resultB {
        // All good!
        case true:
            return
        // False and timed out.
        case false where Date().compare(timeoutDate) == .orderedDescending:
            let error = XCTAssertEventuallyEqualError(
                resultA: resultA,
                resultB: resultB
            )

            XCTFail(
                error.message,
                file: file,
                line: line
            )
            return
        // False but still within timeout limit.
        case false:
            try? await Task.sleep(nanoseconds: 1000000)
        }
    }
}

/// Assert two async expressions are eventually equal.
/// - Parameters:
///   - expressionA: Expression A
///   - expressionB: Expression B
///   - timeout: Time to wait for store state changes. Defaults to `5`
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAssertEventuallyEqual<T: Equatable>(
    _ expressionA: @escaping () async -> T?,
    _ expressionB: @escaping () async -> T?,
    timeout: TimeInterval = 5.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let timeoutDate = Date(timeIntervalSinceNow: timeout)
            
    while true {
        let resultA = await expressionA()
        let resultB = await expressionB()
        
        switch resultA == resultB {
        // All good!
        case true:
            return
        // False and timed out.
        case false where Date().compare(timeoutDate) == .orderedDescending:
            let error = XCTAssertEventuallyEqualError(
                resultA: resultA,
                resultB: resultB
            )

            XCTFail(
                error.message,
                file: file,
                line: line
            )
            return
        // False but still within timeout limit.
        case false:
            try? await Task.sleep(nanoseconds: 1000000)
        }
    }
}

/// Assert a value is eventually true.
/// - Parameters:
///   - expression: The value to assert eventually is true.
///   - timeout: Time to wait for store state changes. Defaults to `5`
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAssertEventuallyTrue(
    _ expression: @escaping @autoclosure () -> Bool,
    timeout: TimeInterval = 5.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    await XCTAssertEventuallyEqual(
        expression(),
        true,
        timeout: timeout,
        file: file,
        line: line
    )
}

/// Assert an async closure thorws an error.
/// - Parameters:
///   - closure: The closure.
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAsyncAssertThrow<T>(
    _ closure: () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await closure()
        XCTFail(
            "Failed to throw error",
            file: file,
            line: line
        )
    } catch {}
}

/// Assert an async closure does not throw.
/// - Parameters:
///   - closure: The closure.
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAsyncAssertNoThrow<T>(
    _ closure: () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await closure()
    } catch {
        XCTFail(
            "Unexpexted error thrown \(error)",
            file: file,
            line: line
        )
    }
}

/// Assert an async closure returns nil.
/// - Parameters:
///   - closure: The closure.
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAsyncAssertNil<T>(
    _ closure: () async -> T?,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let value = await closure()
    XCTAssertNil(
        value,
        file: file,
        line: line
    )
}

/// Assert two async closures return equal values.
/// - Parameters:
///   - expressionA: Expression A.
///   - expressionB: Expression B.
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAsyncAssertEqual<T: Equatable>(
    _ expressionA: @escaping () async -> T,
    _ expressionB: @escaping () async -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let valueA = await expressionA()
    let valueB = await expressionB()

    XCTAssertEqual(
        valueA,
        valueB,
        file: file,
        line: line
    )
}

// MARK: XCTAssertEventuallyEqualError

struct XCTAssertEventuallyEqualError: Error {
    let message: String

    var localizedDescription: String {
        message
    }

    // MARK: Initialization

    init<T: Equatable>(resultA: T?, resultB: T?) {
        var resultADescription = "(null)"
        if let resultA = resultA {
            resultADescription = String(describing: resultA)
        }

        var resultBDescription = "(null)"
        if let resultB = resultB {
            resultBDescription = String(describing: resultB)
        }

        message = """

---------------------------
Failed To Assert Equality
---------------------------

# Result A
\(resultADescription)


# Result B
\(resultBDescription)

---------------------------
"""
    }
}
