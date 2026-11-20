import Foundation
import SeriesAtlasNetwork

struct PeopleService: PeopleServiceProtocol {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func searchPeople(query: String) async throws -> [Person] {
        do {
            let results: [PersonSearchResultDTO] = try await networkClient.get(
                endpoint: "search/people",
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
