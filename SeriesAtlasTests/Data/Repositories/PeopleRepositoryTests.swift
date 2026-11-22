import Foundation
@testable import SeriesAtlas
import Testing

@MainActor
final class PeopleRepositoryTests {
    private let time: TestTime
    private let mockPeopleService: PeopleServiceMock
    private let peopleRepository: PeopleRepository

    init() {
        let time = TestTime()
        self.time = time
        mockPeopleService = PeopleServiceMock()
        peopleRepository = PeopleRepository(
            peopleService: mockPeopleService,
            cache: QueryCache(now: time.now)
        )
    }

    @Test
    func testSearchUsesNormalizedCacheAndRefreshesAtExpiration() async throws {
        let expectedPeople = try Person.mockPeople()
        mockPeopleService.peopleToReturn = expectedPeople
        let query = " \nAlex  Example\t "
        #expect(try await peopleRepository.searchPeople(query: query) == expectedPeople)
        mockPeopleService.peopleToReturn = []

        time.advance(by: 179)
        #expect(try await peopleRepository.searchPeople(query: "ALEX  EXAMPLE") == expectedPeople)
        #expect(mockPeopleService.searchedQueries == [query])

        time.advance(by: 1)
        #expect(try await peopleRepository.searchPeople(query: "alex  example").isEmpty)
        mockPeopleService.peopleToReturn = expectedPeople
        #expect(try await peopleRepository.searchPeople(query: "Alex  Example").isEmpty)
        #expect(try await peopleRepository.searchPeople(query: "Alex Example") == expectedPeople)
        #expect(mockPeopleService.searchedQueries == [query, "alex  example", "Alex Example"])
    }

    @Test
    func testShowsAndPeopleKeepIndependentResultsForSameQuery() async throws {
        let mockShowsService = ShowsServiceMock()
        let showsRepository = ShowsRepository(
            showsService: mockShowsService,
            cache: QueryCache(now: time.now)
        )
        let shows = try Show.mockShows()
        let people = try Person.mockPeople()
        mockShowsService.showsToReturn = shows
        mockPeopleService.peopleToReturn = people

        #expect(try await showsRepository.searchShows(query: "Office") == shows)
        #expect(try await peopleRepository.searchPeople(query: "Office") == people)
        mockShowsService.showsToReturn = []
        mockPeopleService.peopleToReturn = []
        #expect(try await showsRepository.searchShows(query: "OFFICE") == shows)
        #expect(try await peopleRepository.searchPeople(query: "OFFICE") == people)
        #expect(mockShowsService.searchedQueries == ["Office"])
        #expect(mockPeopleService.searchedQueries == ["Office"])
    }

    @Test(arguments: [false, true])
    func testSearchDoesNotCacheFailures(isCancellation: Bool) async throws {
        if isCancellation {
            mockPeopleService.errorToThrow = CancellationError()
            await #expect(throws: CancellationError.self) {
                try await peopleRepository.searchPeople(query: "Alex Example")
            }
        } else {
            mockPeopleService.errorToThrow = PeopleServiceMock.MockError.forcedFailure
            await #expect(throws: PeopleServiceMock.MockError.forcedFailure) {
                try await peopleRepository.searchPeople(query: "Alex Example")
            }
        }

        mockPeopleService.errorToThrow = nil
        let expectedPeople = try Person.mockPeople()
        mockPeopleService.peopleToReturn = expectedPeople
        #expect(try await peopleRepository.searchPeople(query: "Alex Example") == expectedPeople)
        #expect(mockPeopleService.searchedQueries == ["Alex Example", "Alex Example"])
    }

    @Test
    func testCancelledSearchDoesNotCacheResponse() async throws {
        mockPeopleService.peopleToReturn = try Person.mockPeople()
        let task = Task { try await peopleRepository.searchPeople(query: "Alex Example") }
        mockPeopleService.onSearch = { task.cancel() }

        await #expect(throws: CancellationError.self) { try await task.value }
        mockPeopleService.onSearch = nil
        mockPeopleService.peopleToReturn = []
        #expect(try await peopleRepository.searchPeople(query: "Alex Example").isEmpty)
        #expect(mockPeopleService.searchedQueries == ["Alex Example", "Alex Example"])
    }
}
