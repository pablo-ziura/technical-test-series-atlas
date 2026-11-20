import Foundation

struct SearchPeopleUseCase: SearchPeopleUseCaseProtocol {
    private let peopleRepository: PeopleRepositoryProtocol

    init(peopleRepository: PeopleRepositoryProtocol) {
        self.peopleRepository = peopleRepository
    }

    func execute(query: String) async throws -> [Person] {
        let people = try await peopleRepository.searchPeople(query: query)
        try Task.checkCancellation()
        return people
    }
}
