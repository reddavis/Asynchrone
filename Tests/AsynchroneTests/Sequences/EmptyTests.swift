import XCTest
@testable import Asynchrone

final class EmptyTests: XCTestCase {
    func testNothingEmitted() async {
        let values = await Empty<Int>().collect()
        XCTAssertEqual(values, [])
    }
    
    func testSequenceDoesntComplete() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                let timeout: TimeInterval = 1
                let deadline = Date(timeIntervalSinceNow: timeout)

                group.addTask {
                    _ = await Empty<Int>(completeImmediately: false).collect()
                    throw TaskCompletedError()
                }
                
                group.addTask {
                    if deadline.timeIntervalSinceNow > 0 {
                        try await Task.sleep(seconds: timeout)
                    }
                }
                
                try await group.next()
                group.cancelAll()
            }
            
            // All good!
        } catch _ as TaskCompletedError {
            XCTFail("Task incorrectly finished")
        } catch {
            XCTFail("Unknown error thrown \(error)")
        }
    }
}



// MARK: TaskCompletedError

fileprivate struct TaskCompletedError: Error { }
