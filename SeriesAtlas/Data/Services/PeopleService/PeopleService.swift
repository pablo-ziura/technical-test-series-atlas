import Foundation
import SeriesAtlasNetwork

struct PeopleService: PeopleServiceProtocol {
    private let networkClient: NetworkClientProtocol
    private let searchPath: String

    init(networkClient: NetworkClientProtocol, searchPath: String) {
        self.networkClient = networkClient
        self.searchPath = searchPath
    }

    func searchPeople(query: String) async throws -> [Person] {
        do {
            let results: [PersonSearchResultDTO] = try await networkClient.get(
                endpoint: searchPath,
                params: ["q": query]
            )
            let people = try results.map { try PersonMapper.map($0.person) }
            try Task.checkCancellation()
            return people
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw error
        }
    }
}
