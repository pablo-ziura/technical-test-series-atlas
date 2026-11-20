import Foundation

struct ContinuousSearchDelay: SearchDelay {
    func wait() async throws {
        try await ContinuousClock().sleep(for: .milliseconds(300))
    }
}
