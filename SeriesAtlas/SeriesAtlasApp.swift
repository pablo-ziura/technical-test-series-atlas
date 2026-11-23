import SeriesAtlasNetwork
import SwiftUI

@main
@MainActor
struct SeriesAtlasApp: App {
    @State private var coordinator: AppCoordinator

    init() {
        let appConfiguration: AppConfiguration
        do {
            appConfiguration = try AppConfiguration.load()
        } catch {
            preconditionFailure("Unable to load app configuration: \(error)")
        }

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil

        let client = NetworkClient(baseURL: appConfiguration.api.baseURL, session: URLSession(configuration: configuration))

        let showsRepository = ShowsRepository(
            showsService: ShowsService(networkClient: client, searchPath: appConfiguration.api.showsSearchPath),
            cache: QueryCache<[Show]>()
        )

        let peopleRepository = PeopleRepository(
            peopleService: PeopleService(networkClient: client, searchPath: appConfiguration.api.peopleSearchPath),
            cache: QueryCache<[Person]>()
        )

        coordinator = AppCoordinator(
            searchShowsUseCase: SearchShowsUseCase(showsRepository: showsRepository),
            searchPeopleUseCase: SearchPeopleUseCase(peopleRepository: peopleRepository),
            tvmazeURL: appConfiguration.links.tvmazeURL,
            licensingURL: appConfiguration.links.licensingURL
        )
    }

    var body: some Scene {
        WindowGroup {
            coordinator.makeRootView()
        }
    }
}
