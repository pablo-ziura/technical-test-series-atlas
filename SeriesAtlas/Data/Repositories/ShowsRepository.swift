import Foundation

struct ShowsRepository: ShowsRepositoryProtocol {
    private let showsService: ShowsServiceProtocol

    init(showsService: ShowsServiceProtocol) {
        self.showsService = showsService
    }

    func searchShows(query: String) async throws -> [Show] {
        try await showsService.searchShows(query: query)
    }
}
