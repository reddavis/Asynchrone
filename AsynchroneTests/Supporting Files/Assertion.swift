import XCTest


func XCTAssertAsyncThrowsError(
    _ closure: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await closure()
        XCTFail("File: \(file) Line: \(line) -- Failed to throw error")
    }
    catch { }
}


func XCTAsyncAssertThrowsError<T>(
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
    }
    catch { }
}


func XCTAssertAsyncNoThrow(
    _ closure: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await closure()
    }
    catch {
        XCTFail(
            "Unexpexted error thrown \(error)",
            file: file,
            line: line
        )
    }
}


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


func XCTAsyncAssertEqual<T: Equatable>(
    _ expression1: @escaping () async -> T,
    _ expression2: @escaping () async -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let valueA = await expression1()
    let valueB = await expression2()

    XCTAssertEqual(
        valueA,
        valueB,
        file: file,
        line: line
    )
}


func XCTAssertEventuallyEqual<T: Equatable>(
    _ expressionOne: @escaping () async throws -> T,
    _ expressionTwo: @escaping () async throws -> T,
    timeout: TimeInterval = 5.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let handle = Task { () -> Result<Void, _XCTAssertEventuallyEqualError> in
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        var resultOne: T?
        var resultTwo: T?
        
        repeat {
            resultOne = try? await expressionOne()
            resultTwo = try? await expressionTwo()
            
            if resultOne == resultTwo
            {
                return .success(())
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
        } while Date().compare(timeoutDate) == .orderedAscending
        
        let error = _XCTAssertEventuallyEqualError(
            resultOne: resultOne,
            resultTwo: resultTwo
        )
        return .failure(error)
    }
    
    let result = await handle.value
    switch result {
    case .success:
        return
    case .failure(let error):
        XCTFail(error.message, file: file, line: line)
    }
}



// MARK: _XCTAssertEventuallyEqualError

private struct _XCTAssertEventuallyEqualError: Error {
    let message: String
    
    var localizedDescription: String {
        self.message
    }
    
    // MARK: Initialization
    
    init<T: Equatable>(resultOne: T?, resultTwo: T?) {
        var resultOneDescription = "(null)"
        if let resultOne = resultOne {
            resultOneDescription = String(describing: resultOne)
        }
        
        var resultTwoDescription = "(null)"
        if let resultTwo = resultTwo {
            resultTwoDescription = String(describing: resultTwo)
        }
        
        self.message = """

---------------------------
Failed To Assert Equality
---------------------------

# Result One
\(resultOneDescription)


# Result Two
\(resultTwoDescription)

---------------------------
"""
    }
}
