import Foundation
import SeriesAtlasNetwork

struct ShowsService: ShowsServiceProtocol {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func searchShows(query: String) async throws -> [Show] {
        do {
            let results: [ShowSearchResultDTO] = try await networkClient.get(
                endpoint: "search/shows",
                params: ["q": query]
            )
            var shows: [Show] = []
            for result in results {
                shows.append(try await ShowMapper.map(result.show))
            }
            try Task.checkCancellation()
            return shows
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw error
        }
    }
}
