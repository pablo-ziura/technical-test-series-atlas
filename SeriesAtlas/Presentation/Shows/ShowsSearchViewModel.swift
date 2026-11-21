import Foundation
import Observation

@MainActor
@Observable
final class ShowsSearchViewModel {
    private let searchShowsUseCase: SearchShowsUseCaseProtocol
    private var searchTask: Task<Void, Never>?

    var state: SearchState<Show> = .idle
    var query = ""
    private(set) var submittedQuery = ""

    init(searchShowsUseCase: SearchShowsUseCaseProtocol) {
        self.searchShowsUseCase = searchShowsUseCase
    }

    func search() {
        performSearch(query: query.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func retry() {
        performSearch(query: submittedQuery)
    }

    private func performSearch(query: String) {
        searchTask?.cancel()
        submittedQuery = query

        guard !query.isEmpty else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading
        searchTask = Task { [weak self, searchShowsUseCase] in
            do {
                let shows = try await searchShowsUseCase.execute(query: query)
                guard !Task.isCancelled, let self else { return }
                state = shows.isEmpty ? .empty : .results(shows)
            } catch {
                guard !Task.isCancelled, let self else { return }
                if error is CancellationError || (error as? URLError)?.code == .cancelled {
                    state = .idle
                } else {
                    state = .failure("Unable to search shows. Please try again.")
                }
            }
        }
    }
}
