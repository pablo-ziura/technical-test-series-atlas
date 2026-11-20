import Foundation

protocol SearchDelay: Sendable {
    func wait() async throws
}
