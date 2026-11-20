@testable import SeriesAtlas
import Testing

@MainActor
final class SearchShowsUseCaseTests {
    private let mockShowsRepository: ShowsRepositoryMock
    private let searchShowsUseCase: SearchShowsUseCase

    init() {
        mockShowsRepository = ShowsRepositoryMock()
        searchShowsUseCase = SearchShowsUseCase(showsRepository: mockShowsRepository)
    }

    @Test
    func testExecuteSuccess() async throws {
        let expectedShows = try Show.mockShows()
        mockShowsRepository.showsToReturn = expectedShows

        let result = try await searchShowsUseCase.execute(query: " \nThe  Office\t ")

        #expect(result == expectedShows)
        #expect(mockShowsRepository.searchShowsCalledWith == " \nThe  Office\t ")
    }

    @Test(arguments: ["", " \t\n\r "])
    func testExecuteForwardsEmptyQueries(query: String) async throws {
        let expectedShows = try Show.mockShows()
        mockShowsRepository.showsToReturn = expectedShows

        let result = try await searchShowsUseCase.execute(query: query)

        #expect(result == expectedShows)
        #expect(mockShowsRepository.searchShowsCalledWith == query)
    }

    @Test
    func testExecuteWithoutResults() async throws {
        let result = try await searchShowsUseCase.execute(query: "Unknown show")

        #expect(result.isEmpty)
        #expect(mockShowsRepository.searchShowsCalledWith == "Unknown show")
    }

    @Test
    func testExecuteFailure() async {
        mockShowsRepository.errorToThrow = ShowsRepositoryMock.MockError.forcedFailure

        await #expect(throws: ShowsRepositoryMock.MockError.forcedFailure) {
            try await searchShowsUseCase.execute(query: "The Office")
        }
    }

    @Test
    func testExecuteRepositoryCancellation() async {
        mockShowsRepository.errorToThrow = CancellationError()

        await #expect(throws: CancellationError.self) {
            try await searchShowsUseCase.execute(query: "The Office")
        }
    }

    @Test
    func testExecuteWhenAlreadyCancelled() async {
        let task = Task { try await searchShowsUseCase.execute(query: "The Office") }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test
    func testExecuteWhenCancelledDuringSearch() async throws {
        mockShowsRepository.showsToReturn = try Show.mockShows()
        let task = Task { try await searchShowsUseCase.execute(query: "The Office") }
        mockShowsRepository.onSearch = { task.cancel() }
        defer { mockShowsRepository.onSearch = nil }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(mockShowsRepository.searchShowsCalledWith == "The Office")
    }
}
