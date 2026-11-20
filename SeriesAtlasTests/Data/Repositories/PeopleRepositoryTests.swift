import Foundation
@testable import SeriesAtlas
import Testing

@MainActor
final class PeopleRepositoryTests {
    private let mockPeopleService: PeopleServiceMock
    private let peopleRepository: PeopleRepository

    init() {
        mockPeopleService = PeopleServiceMock()
        peopleRepository = PeopleRepository(peopleService: mockPeopleService)
    }

    @Test
    func testSearchCallsServiceForEveryRequest() async throws {
        let expectedPeople = try Person.mockPeople()
        mockPeopleService.peopleToReturn = expectedPeople

        let result = try await peopleRepository.searchPeople(query: " \nAlex  Example\t ")
        mockPeopleService.peopleToReturn = []
        let nextResult = try await peopleRepository.searchPeople(query: " \nAlex  Example\t ")

        #expect(result == expectedPeople)
        #expect(nextResult.isEmpty)
        #expect(mockPeopleService.searchedQueries == [" \nAlex  Example\t ", " \nAlex  Example\t "])
    }

    @Test
    func testSearchForwardsEmptyQueriesToService() async throws {
        let queries = ["", " \t\n\r "]
        for query in queries {
            _ = try await peopleRepository.searchPeople(query: query)
        }
        #expect(mockPeopleService.searchedQueries == queries)
    }

    @Test(arguments: [false, true])
    func testSearchPropagatesFailures(isCancellation: Bool) async {
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
        #expect(mockPeopleService.searchedQueries == ["Alex Example"])
    }
}
