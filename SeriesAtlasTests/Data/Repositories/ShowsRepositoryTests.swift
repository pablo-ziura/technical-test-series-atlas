import Foundation
@testable import SeriesAtlas
import Testing

@MainActor
final class ShowsRepositoryTests {
    private let mockShowsService: ShowsServiceMock
    private let showsRepository: ShowsRepository

    init() {
        mockShowsService = ShowsServiceMock()
        showsRepository = ShowsRepository(showsService: mockShowsService)
    }

    @Test
    func testSearchCallsServiceForEveryRequest() async throws {
        let expectedShows = try Show.mockShows()
        mockShowsService.showsToReturn = expectedShows

        let result = try await showsRepository.searchShows(query: " \nThe  Office\t ")
        mockShowsService.showsToReturn = []
        let nextResult = try await showsRepository.searchShows(query: "The  Office")

        #expect(result == expectedShows)
        #expect(nextResult.isEmpty)
        #expect(mockShowsService.searchedQueries == [" \nThe  Office\t ", "The  Office"])
    }

    @Test
    func testSearchForwardsEmptyQueriesToService() async throws {
        let queries = ["", " \t\n\r "]
        for query in queries {
            _ = try await showsRepository.searchShows(query: query)
        }
        #expect(mockShowsService.searchedQueries == queries)
    }

    @Test(arguments: [false, true])
    func testSearchPropagatesFailures(isCancellation: Bool) async {
        if isCancellation {
            mockShowsService.errorToThrow = CancellationError()
            await #expect(throws: CancellationError.self) {
                try await showsRepository.searchShows(query: "The Office")
            }
        } else {
            mockShowsService.errorToThrow = ShowsServiceMock.MockError.forcedFailure
            await #expect(throws: ShowsServiceMock.MockError.forcedFailure) {
                try await showsRepository.searchShows(query: "The Office")
            }
        }
        #expect(mockShowsService.searchedQueries == ["The Office"])
    }
}
