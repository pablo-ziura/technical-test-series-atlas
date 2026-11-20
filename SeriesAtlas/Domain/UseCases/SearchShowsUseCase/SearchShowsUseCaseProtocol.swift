import Foundation

protocol SearchShowsUseCaseProtocol: Sendable {
    func execute(query: String) async throws -> [Show]
}
