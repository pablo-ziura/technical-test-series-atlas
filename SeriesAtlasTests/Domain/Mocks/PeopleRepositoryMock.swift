@testable import SeriesAtlas

@MainActor
final class PeopleRepositoryMock: PeopleRepositoryProtocol {
    enum MockError: Error {
        case forcedFailure
    }

    var peopleToReturn: [Person] = []
    var errorToThrow: Error?
    var onSearch: (() -> Void)?
    private(set) var searchPeopleCalledWith: String?

    @MainActor
    func searchPeople(query: String) async throws -> [Person] {
        searchPeopleCalledWith = query
        onSearch?()
        if let errorToThrow { throw errorToThrow }
        return peopleToReturn
    }
}
