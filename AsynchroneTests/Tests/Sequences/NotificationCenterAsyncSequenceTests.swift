import XCTest
@testable import Asynchrone

final class NotificationCenterAsyncSequenceTests: XCTestCase {
    private var task: Task<Void, Error>!
    private var notifications: [Notification] = []
    
    override func setUp() async throws {
        self.task = NotificationCenter.default
            .sequence(for: .testNotification)
            .sink(
                receiveValue: { [weak self] in self?.notifications.append($0) }
            )
    }
    
    func testNotificationsAreReceived() async throws {
        NotificationCenter.default.post(name: .testNotification, object: 1)
        NotificationCenter.default.post(name: .testNotification, object: 2)
        await XCTAssertEventuallyEqual(
            self.notifications.map { $0.object as? Int },
            [1, 2]
        )
    }
}

// MARK: Notification name

private extension Notification.Name {
    static let testNotification = Notification.Name("testNotification")
}
