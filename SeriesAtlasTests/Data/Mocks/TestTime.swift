import Foundation
import Synchronization

final class TestTime: Sendable {
    private let date = Mutex(Date(timeIntervalSince1970: 0))

    func now() -> Date {
        date.withLock { $0 }
    }

    func advance(by interval: TimeInterval) {
        date.withLock { $0.addTimeInterval(interval) }
    }
}
