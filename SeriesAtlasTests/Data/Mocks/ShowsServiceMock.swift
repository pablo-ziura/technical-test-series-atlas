@testable import SeriesAtlas

@MainActor
final class ShowsServiceMock: ShowsServiceProtocol {
    enum MockError: Error {
        case forcedFailure
    }

    var showsToReturn: [Show] = []
    var errorToThrow: Error?
    var onSearch: (() -> Void)?
    private(set) var searchedQueries: [String] = []

    @MainActor
    func searchShows(query: String) async throws -> [Show] {
        searchedQueries.append(query)
        onSearch?()
        if let errorToThrow { throw errorToThrow }
        return showsToReturn
    }
}
