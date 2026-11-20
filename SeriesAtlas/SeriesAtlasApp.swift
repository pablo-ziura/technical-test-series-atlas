import SeriesAtlasNetwork
import SwiftUI

@main
@MainActor
struct SeriesAtlasApp: App {
    @State private var coordinator: AppCoordinator

    init() {
        guard let baseURL = URL(string: "https://api.tvmaze.com") else {
            preconditionFailure("Invalid TVmaze base URL.")
        }

        let client = NetworkClient(baseURL: baseURL, session: URLSession(configuration: .default))
        let showsRepository = ShowsRepository(showsService: ShowsService(networkClient: client))
        let peopleRepository = PeopleRepository(peopleService: PeopleService(networkClient: client))

        coordinator = AppCoordinator(
            searchShowsUseCase: SearchShowsUseCase(showsRepository: showsRepository),
            searchPeopleUseCase: SearchPeopleUseCase(peopleRepository: peopleRepository)
        )
    }

    var body: some Scene {
        WindowGroup {
            coordinator.makeRootView()
        }
    }
}
