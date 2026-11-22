import Foundation

struct ShowsRepository: ShowsRepositoryProtocol {
    private let showsService: ShowsServiceProtocol
    private let cache: QueryCache<[Show]>

    init(showsService: ShowsServiceProtocol, cache: QueryCache<[Show]> = QueryCache()) {
        self.showsService = showsService
        self.cache = cache
    }

    func searchShows(query: String) async throws -> [Show] {
        let cachedShows = await cache.value(for: query)
        try Task.checkCancellation()
        if let cachedShows { return cachedShows }

        let shows = try await showsService.searchShows(query: query)
        try await cache.insert(shows, for: query)
        return shows
    }
}
