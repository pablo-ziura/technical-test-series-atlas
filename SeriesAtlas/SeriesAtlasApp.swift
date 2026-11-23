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

        let client = Self.makeNetworkClient(api: appConfiguration.api)

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

    private static func makeNetworkClient(api: AppConfiguration.API) -> any NetworkClientProtocol {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let scenarioName = ProcessInfo.processInfo.environment["SERIES_ATLAS_UI_TEST_SCENARIO"] ?? "standard"
            guard let scenario = UITestNetworkClient.Scenario(rawValue: scenarioName) else {
                preconditionFailure("Unknown UI test scenario: \(scenarioName)")
            }
            return UITestNetworkClient(
                scenario: scenario,
                showsSearchPath: api.showsSearchPath,
                peopleSearchPath: api.peopleSearchPath
            )
        }
        #endif

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return NetworkClient(baseURL: api.baseURL, session: URLSession(configuration: configuration))
    }
}
