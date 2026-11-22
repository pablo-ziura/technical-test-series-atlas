import Foundation

struct PeopleRepository: PeopleRepositoryProtocol {
    private let peopleService: PeopleServiceProtocol
    private let cache: QueryCache<[Person]>

    init(peopleService: PeopleServiceProtocol, cache: QueryCache<[Person]> = QueryCache()) {
        self.peopleService = peopleService
        self.cache = cache
    }

    func searchPeople(query: String) async throws -> [Person] {
        let cachedPeople = await cache.value(for: query)
        try Task.checkCancellation()
        if let cachedPeople { return cachedPeople }

        let people = try await peopleService.searchPeople(query: query)
        try await cache.insert(people, for: query)
        return people
    }
}
