@testable import SeriesAtlas

@MainActor
final class PeopleServiceMock: PeopleServiceProtocol {
    enum MockError: Error {
        case forcedFailure
    }

    var peopleToReturn: [Person] = []
    var errorToThrow: Error?
    private(set) var searchedQueries: [String] = []

    @MainActor
    func searchPeople(query: String) async throws -> [Person] {
        searchedQueries.append(query)
        if let errorToThrow { throw errorToThrow }
        return peopleToReturn
    }
}
