import Foundation
import Observation

@MainActor
@Observable
final class PeopleSearchViewModel {
    private let searchPeopleUseCase: SearchPeopleUseCaseProtocol
    private let delay: SearchDelay
    private var searchTask: Task<Void, Never>?

    var state: SearchState<Person> = .idle

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            search(debounced: true)
        }
    }

    init(
        searchPeopleUseCase: SearchPeopleUseCaseProtocol,
        delay: SearchDelay = ContinuousSearchDelay()
    ) {
        self.searchPeopleUseCase = searchPeopleUseCase
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
        searchTask = Task { [weak self, searchPeopleUseCase, delay] in
            do {
                if debounced {
                    try await delay.wait()
                }
                try Task.checkCancellation()
                let people = try await searchPeopleUseCase.execute(query: currentQuery)
                guard !Task.isCancelled, let self else { return }
                state = people.isEmpty ? .empty : .results(people)
            } catch {
                guard !Task.isCancelled, let self else { return }
                if error is CancellationError || (error as? URLError)?.code == .cancelled {
                    state = .idle
                } else {
                    state = .failure("Unable to search people. Please try again.")
                }
            }
        }
    }
}
