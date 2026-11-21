import Foundation
import Observation

@MainActor
@Observable
final class PeopleSearchViewModel {
    private let searchPeopleUseCase: SearchPeopleUseCaseProtocol
    private var searchTask: Task<Void, Never>?

    var state: SearchState<Person> = .idle
    var query = ""
    private(set) var submittedQuery = ""

    init(searchPeopleUseCase: SearchPeopleUseCaseProtocol) {
        self.searchPeopleUseCase = searchPeopleUseCase
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
        searchTask = Task { [weak self, searchPeopleUseCase] in
            do {
                let people = try await searchPeopleUseCase.execute(query: query)
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
