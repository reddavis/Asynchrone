import XCTest

/// Assert two expressions are eventually equal.
/// - Parameters:
///   - expressionA: Expression A
///   - expressionB: Expression B
///   - timeout: Time to wait for store state changes. Defaults to `5`
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
func XCTAssertEventuallyEqual<T: Equatable>(
    _ expressionA: @escaping @autoclosure () -> T?,
    _ expressionB: @escaping @autoclosure () -> T?,
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
            try? await Task.sleep(nanoseconds: 10000000)
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
func XCTAsyncAssertEventuallyEqual<T: Equatable>(
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
            try? await Task.sleep(nanoseconds: 10000000)
        }
    }
}


/// Assert an async closure thorws an error.
/// - Parameters:
///   - closure: The closure.
///   - file: The file where this assertion is being called. Defaults to `#filePath`.
///   - line: The line in the file where this assertion is being called. Defaults to `#line`.
public func XCTAsyncAssertThrow<T>(
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
public func XCTAsyncAssertNoThrow<T>(
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
public func XCTAsyncAssertNil<T>(
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
