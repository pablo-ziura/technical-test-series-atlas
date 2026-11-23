@testable import SeriesAtlas
import Testing

@MainActor
final class PeopleSearchViewModelTests {
    enum ResponseOutcome: CaseIterable, Sendable {
        case results
        case empty
        case failure
    }

    private let useCase: SearchPeopleUseCaseMock
    private let viewModel: PeopleSearchViewModel

    init() {
        useCase = SearchPeopleUseCaseMock()
        viewModel = PeopleSearchViewModel(searchPeopleUseCase: useCase)
    }

    @Test(arguments: ResponseOutcome.allCases)
    func testSearchPublishesCurrentResponse(outcome: ResponseOutcome) async throws {
        defer { useCase.close() }
        #expect(viewModel.state == .idle)

        viewModel.query = " \nFirst query\t "
        viewModel.search()
        let task = try #require(viewModel.searchTask)
        #expect(viewModel.state == .loading)
        #expect(viewModel.submittedQuery == "First query")
        try await useCase.waitForInvocation(0)
        #expect(useCase.queries == ["First query"])

        let people = try Person.mockPeople()
        switch outcome {
        case .results:
            try useCase.completeInvocation(0, with: .success(people))
        case .empty:
            try useCase.completeInvocation(0, with: .success([]))
        case .failure:
            try useCase.completeInvocation(0, with: .failure(SearchPeopleUseCaseMock.MockError.forcedFailure))
        }
        await task.value

        switch outcome {
        case .results:
            #expect(viewModel.state == .results(people))
        case .empty:
            #expect(viewModel.state == .empty)
        case .failure:
            guard case .failure = viewModel.state else {
                Issue.record("Expected a recoverable search failure.")
                return
            }
        }
    }

    @Test(arguments: [false, true])
    func testSupersededResponsePreservesLatestResults(fails: Bool) async throws {
        defer { useCase.close() }
        let previousPeople = try Person.mockPeople()
        let latestPeople = Array(previousPeople.reversed())
        viewModel.query = "First query"
        viewModel.search()
        let previousTask = try #require(viewModel.searchTask)
        try await useCase.waitForInvocation(0)

        viewModel.query = "Second query"
        viewModel.search()
        let latestTask = try #require(viewModel.searchTask)
        try await useCase.waitForInvocation(1)
        #expect(previousTask.isCancelled)
        #expect(viewModel.state == .loading)
        #expect(useCase.queries == ["First query", "Second query"])

        try useCase.completeInvocation(1, with: .success(latestPeople))
        await latestTask.value
        #expect(viewModel.state == .results(latestPeople))

        let lateResponse: Result<[Person], any Error> = fails
            ? .failure(SearchPeopleUseCaseMock.MockError.forcedFailure)
            : .success(previousPeople)
        try useCase.completeInvocation(0, with: lateResponse)
        // Esperar la tarea completa garantiza que el ViewModel ya procesó la respuesta antigua.
        await previousTask.value

        #expect(viewModel.state == .results(latestPeople))
        #expect(viewModel.submittedQuery == "Second query")
    }

    @Test(arguments: ["Another query", ""])
    func testEditingPreservesSubmittedSearchAndRetry(editedQuery: String) async throws {
        defer { useCase.close() }
        viewModel.query = " \nFirst query\t "
        viewModel.search()
        let firstTask = try #require(viewModel.searchTask)
        try await useCase.waitForInvocation(0)

        viewModel.query = editedQuery
        #expect(viewModel.state == .loading)
        #expect(viewModel.submittedQuery == "First query")
        #expect(useCase.queries == ["First query"])
        #expect(!firstTask.isCancelled)

        try useCase.completeInvocation(0, with: .failure(SearchPeopleUseCaseMock.MockError.forcedFailure))
        await firstTask.value
        guard case .failure = viewModel.state else {
            Issue.record("Expected a failed search before retrying.")
            return
        }

        viewModel.retry()
        let retryTask = try #require(viewModel.searchTask)
        #expect(viewModel.state == .loading)
        try await useCase.waitForInvocation(1)
        #expect(useCase.queries == ["First query", "First query"])

        let people = try Person.mockPeople()
        try useCase.completeInvocation(1, with: .success(people))
        await retryTask.value
        #expect(viewModel.state == .results(people))
        #expect(viewModel.submittedQuery == "First query")
        #expect(viewModel.query == editedQuery)
    }

    @Test(arguments: [false, true])
    func testSubmittingWhitespaceCancelsPendingSearchAndStaysIdle(fails: Bool) async throws {
        defer { useCase.close() }
        viewModel.query = "First query"
        viewModel.search()
        let task = try #require(viewModel.searchTask)
        try await useCase.waitForInvocation(0)

        viewModel.query = " \t\n "
        viewModel.search()
        #expect(task.isCancelled)
        #expect(viewModel.state == .idle)
        #expect(viewModel.submittedQuery.isEmpty)
        #expect(useCase.queries == ["First query"])

        let lateResponse: Result<[Person], any Error> = fails
            ? .failure(SearchPeopleUseCaseMock.MockError.forcedFailure)
            : .success(try Person.mockPeople())
        try useCase.completeInvocation(0, with: lateResponse)
        await task.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.submittedQuery.isEmpty)
        #expect(useCase.queries == ["First query"])
    }
}
