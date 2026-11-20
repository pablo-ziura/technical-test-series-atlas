@testable import SeriesAtlas
import Testing

@MainActor
final class SearchPeopleUseCaseTests {
    private let mockPeopleRepository: PeopleRepositoryMock
    private let searchPeopleUseCase: SearchPeopleUseCase

    init() {
        mockPeopleRepository = PeopleRepositoryMock()
        searchPeopleUseCase = SearchPeopleUseCase(peopleRepository: mockPeopleRepository)
    }

    @Test(arguments: [" \nAlex  Example\t ", "", " \t\n\r "])
    func testExecutePreservesResultsAndQuery(query: String) async throws {
        let expectedPeople = try Person.mockPeople()
        mockPeopleRepository.peopleToReturn = expectedPeople

        let result = try await searchPeopleUseCase.execute(query: query)

        #expect(result == expectedPeople)
        #expect(mockPeopleRepository.searchPeopleCalledWith == query)
    }

    @Test
    func testExecuteWithoutResults() async throws {
        let result = try await searchPeopleUseCase.execute(query: "Unknown person")

        #expect(result.isEmpty)
        #expect(mockPeopleRepository.searchPeopleCalledWith == "Unknown person")
    }

    @Test
    func testExecuteFailure() async {
        mockPeopleRepository.errorToThrow = PeopleRepositoryMock.MockError.forcedFailure

        await #expect(throws: PeopleRepositoryMock.MockError.forcedFailure) {
            try await searchPeopleUseCase.execute(query: "Alex Example")
        }
    }

    @Test
    func testExecuteRepositoryCancellation() async {
        mockPeopleRepository.errorToThrow = CancellationError()

        await #expect(throws: CancellationError.self) {
            try await searchPeopleUseCase.execute(query: "Alex Example")
        }
    }

    @Test
    func testExecuteWhenAlreadyCancelled() async {
        let task = Task { try await searchPeopleUseCase.execute(query: "Alex Example") }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test(arguments: [false, true])
    func testExecuteDiscardsResponseAfterCancellation(hasResults: Bool) async throws {
        mockPeopleRepository.peopleToReturn = hasResults ? try Person.mockPeople() : []
        let task = Task { try await searchPeopleUseCase.execute(query: "Alex Example") }
        mockPeopleRepository.onSearch = { task.cancel() }
        defer { mockPeopleRepository.onSearch = nil }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(mockPeopleRepository.searchPeopleCalledWith == "Alex Example")
    }
}
