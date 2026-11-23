import Foundation

enum UIPreviewData {
    static let sourceURL: URL = {
        guard let url = URL(string: "https://example.com") else {
            preconditionFailure("Invalid preview source URL.")
        }
        return url
    }()

    static let show = Show(
        id: 1,
        name: "The Extraordinary Adventures of a Very Long Show Title",
        summary: "A group of friends travels across unfamiliar places, discovering the stories and people that connect them.",
        genres: ["Drama", "Adventure", "Science-Fiction"],
        language: "English",
        rating: 8.5,
        imageURL: nil,
        tvmazeURL: sourceURL
    )

    static let person = Person(
        id: 1,
        name: "Alexandra Catherine Montgomery",
        country: "United Kingdom",
        gender: "Female",
        birthday: "1985-06-15",
        deathday: nil,
        imageURL: nil,
        tvmazeURL: sourceURL
    )

    @MainActor
    static func makeCoordinator(selectedTab: AppTab = .shows) -> AppCoordinator {
        let coordinator = AppCoordinator(
            searchShowsUseCase: ShowsUseCase(),
            searchPeopleUseCase: PeopleUseCase(),
            tvmazeURL: sourceURL,
            licensingURL: sourceURL
        )
        coordinator.router.selectedTab = selectedTab
        coordinator.showsCoordinator.viewModel.state = .results([show])
        coordinator.peopleCoordinator.viewModel.state = .results([person])
        return coordinator
    }

    private struct ShowsUseCase: SearchShowsUseCaseProtocol {
        func execute(query: String) async throws -> [Show] {
            [show]
        }
    }

    private struct PeopleUseCase: SearchPeopleUseCaseProtocol {
        func execute(query: String) async throws -> [Person] {
            [person]
        }
    }
}
