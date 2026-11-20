import Foundation

struct SearchShowsUseCase: SearchShowsUseCaseProtocol {
    private let showsRepository: ShowsRepositoryProtocol

    init(showsRepository: ShowsRepositoryProtocol) {
        self.showsRepository = showsRepository
    }

    func execute(query: String) async throws -> [Show] {
        let shows = try await showsRepository.searchShows(query: query)
        try Task.checkCancellation()
        return shows
    }
}
