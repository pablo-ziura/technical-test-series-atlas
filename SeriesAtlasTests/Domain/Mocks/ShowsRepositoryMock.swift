@testable import SeriesAtlas

@MainActor
final class ShowsRepositoryMock: ShowsRepositoryProtocol {
    enum MockError: Error {
        case forcedFailure
    }

    var showsToReturn: [Show] = []
    var errorToThrow: Error?
    var onSearch: (() -> Void)?
    private(set) var searchShowsCalledWith: String?

    @MainActor
    func searchShows(query: String) async throws -> [Show] {
        searchShowsCalledWith = query
        onSearch?()
        if let errorToThrow { throw errorToThrow }
        return showsToReturn
    }
}
