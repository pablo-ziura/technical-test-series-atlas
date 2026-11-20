import Foundation

protocol ShowsServiceProtocol: Sendable {
    func searchShows(query: String) async throws -> [Show]
}
