import Foundation
import Observation

@MainActor
@Observable
final class ShowsSearchViewModel {
    private let searchShowsUseCase: SearchShowsUseCaseProtocol
    private let delay: SearchDelay
    private var searchTask: Task<Void, Never>?

    var state: SearchState<Show> = .idle

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            search(debounced: true)
        }
    }

    init(
        searchShowsUseCase: SearchShowsUseCaseProtocol,
        delay: SearchDelay = ContinuousSearchDelay()
    ) {
        self.searchShowsUseCase = searchShowsUseCase
        self.delay = delay
    }

    func retry() {
        search(debounced: false)
    }

    private func search(debounced: Bool) {
        searchTask?.cancel()
        let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !currentQuery.isEmpty else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading
        searchTask = Task { [weak self, searchShowsUseCase, delay] in
            do {
                if debounced {
                    try await delay.wait()
                }
                try Task.checkCancellation()
                let shows = try await searchShowsUseCase.execute(query: currentQuery)
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
