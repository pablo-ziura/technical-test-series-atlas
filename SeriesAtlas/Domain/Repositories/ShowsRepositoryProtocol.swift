import Foundation

nonisolated protocol ShowsRepositoryProtocol: Sendable {
    func searchShows(query: String) async throws -> [Show]
}
