import Foundation

struct PeopleRepository: PeopleRepositoryProtocol {
    private let peopleService: PeopleServiceProtocol

    init(peopleService: PeopleServiceProtocol) {
        self.peopleService = peopleService
    }

    func searchPeople(query: String) async throws -> [Person] {
        try await peopleService.searchPeople(query: query)
    }
}
