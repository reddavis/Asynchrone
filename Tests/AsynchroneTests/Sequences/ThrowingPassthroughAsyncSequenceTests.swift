import XCTest
@testable import Asynchrone

final class ThrowingPassthroughAsyncSequenceTests: XCTestCase {
    private var sequence: ThrowingPassthroughAsyncSequence<Int>!
    
    // MARK: Setup
    
    override func setUpWithError() throws {
        self.sequence = .init()
    }
    
    // MARK: Tests
    
    func testSequence() async throws {
        self.sequence.yield(0)
        self.sequence.yield(1)
        self.sequence.finish(with: 2)
        
        let values = try await self.sequence.collect()
        XCTAssertEqual(values, [0, 1, 2])
    }
    
    func testSequenceThrows() async throws {
        self.sequence.finish(throwing: TestError())
        
        await XCTAsyncAssertThrow {
            try await self.sequence.collect()
        }
    }
}
