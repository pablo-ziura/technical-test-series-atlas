import Foundation
import SeriesAtlasNetwork

struct ShowsService: ShowsServiceProtocol {
    private let networkClient: NetworkClientProtocol
    private let searchPath: String

    init(networkClient: NetworkClientProtocol, searchPath: String) {
        self.networkClient = networkClient
        self.searchPath = searchPath
    }

    func searchShows(query: String) async throws -> [Show] {
        do {
            let results: [ShowSearchResultDTO] = try await networkClient.get(
                endpoint: searchPath,
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
