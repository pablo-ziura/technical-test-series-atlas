import Foundation
import SwiftUI

@MainActor
final class AppCoordinator {
    let router: AppRouter
    let showsCoordinator: ShowsCoordinator
    let peopleCoordinator: PeopleCoordinator
    let settingsCoordinator: SettingsCoordinator

    init(
        searchShowsUseCase: any SearchShowsUseCaseProtocol,
        searchPeopleUseCase: any SearchPeopleUseCaseProtocol
    ) {
        router = AppRouter()
        showsCoordinator = ShowsCoordinator(searchShowsUseCase: searchShowsUseCase)
        peopleCoordinator = PeopleCoordinator(searchPeopleUseCase: searchPeopleUseCase)
        settingsCoordinator = SettingsCoordinator()
    }

    func makeRootView() -> some View {
        MainTabView(
            showsCoordinator: showsCoordinator,
            peopleCoordinator: peopleCoordinator,
            settingsCoordinator: settingsCoordinator
        )
        .environment(router)
    }
}
