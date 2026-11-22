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

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil

        let client = NetworkClient(baseURL: baseURL, session: URLSession(configuration: configuration))

        let showsRepository = ShowsRepository(
            showsService: ShowsService(networkClient: client),
            cache: QueryCache<[Show]>()
        )

        let peopleRepository = PeopleRepository(
            peopleService: PeopleService(networkClient: client),
            cache: QueryCache<[Person]>()
        )

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
