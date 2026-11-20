import Foundation

nonisolated protocol SearchShowsUseCaseProtocol: Sendable {
    func execute(query: String) async throws -> [Show]
}
