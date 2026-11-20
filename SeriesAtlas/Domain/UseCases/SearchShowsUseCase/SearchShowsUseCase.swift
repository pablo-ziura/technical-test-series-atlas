import Foundation

struct SearchShowsUseCase: SearchShowsUseCaseProtocol {
    private let showsRepository: ShowsRepositoryProtocol

    init(showsRepository: ShowsRepositoryProtocol) {
        self.showsRepository = showsRepository
    }

    func execute(query: String) async throws -> [Show] {
        try Task.checkCancellation()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let shows = try await showsRepository.searchShows(query: trimmedQuery)
        try Task.checkCancellation()
        return shows
    }
}
