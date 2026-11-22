@testable import SeriesAtlas
import Testing

@MainActor
final class ShowsSearchViewModelTests {
    enum ResponseOutcome: CaseIterable, Sendable {
        case results
        case empty
        case failure
    }

    private let useCase: SearchShowsUseCaseMock
    private let viewModel: ShowsSearchViewModel

    init() {
        useCase = SearchShowsUseCaseMock()
        viewModel = ShowsSearchViewModel(searchShowsUseCase: useCase)
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

        let shows = try Show.mockShows()
        switch outcome {
        case .results:
            try useCase.completeInvocation(0, with: .success(shows))
        case .empty:
            try useCase.completeInvocation(0, with: .success([]))
        case .failure:
            try useCase.completeInvocation(0, with: .failure(SearchShowsUseCaseMock.MockError.forcedFailure))
        }
        await task.value

        switch outcome {
        case .results:
            #expect(viewModel.state == .results(shows))
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
        let previousShows = try Show.mockShows()
        let latestShows = Array(previousShows.reversed())
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

        try useCase.completeInvocation(1, with: .success(latestShows))
        await latestTask.value
        #expect(viewModel.state == .results(latestShows))

        let lateResponse: Result<[Show], any Error> = fails
            ? .failure(SearchShowsUseCaseMock.MockError.forcedFailure)
            : .success(previousShows)
        try useCase.completeInvocation(0, with: lateResponse)
        // Esperar la tarea completa garantiza que el ViewModel ya procesó la respuesta antigua.
        await previousTask.value

        #expect(viewModel.state == .results(latestShows))
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

        try useCase.completeInvocation(0, with: .failure(SearchShowsUseCaseMock.MockError.forcedFailure))
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

        let shows = try Show.mockShows()
        try useCase.completeInvocation(1, with: .success(shows))
        await retryTask.value
        #expect(viewModel.state == .results(shows))
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

        let lateResponse: Result<[Show], any Error> = fails
            ? .failure(SearchShowsUseCaseMock.MockError.forcedFailure)
            : .success(try Show.mockShows())
        try useCase.completeInvocation(0, with: lateResponse)
        await task.value

        #expect(viewModel.state == .idle)
        #expect(viewModel.submittedQuery.isEmpty)
        #expect(useCase.queries == ["First query"])
    }
}
