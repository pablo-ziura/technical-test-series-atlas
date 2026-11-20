import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    let showsCoordinator: ShowsCoordinator
    let peopleCoordinator: PeopleCoordinator
    let settingsCoordinator: SettingsCoordinator

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Shows", systemImage: "tv", value: AppTab.shows) {
                NavigationStack(path: $router.showsPath) {
                    showsCoordinator.makeSearchView()
                        .navigationDestination(for: ShowsRoute.self) { route in
                            showsCoordinator.destination(for: route)
                        }
                }
            }

            Tab("People", systemImage: "person.2", value: AppTab.people) {
                NavigationStack(path: $router.peoplePath) {
                    peopleCoordinator.makeSearchView()
                        .navigationDestination(for: PeopleRoute.self) { route in
                            peopleCoordinator.destination(for: route)
                        }
                }
            }

            Tab("Settings", systemImage: "gear", value: AppTab.settings) {
                NavigationStack {
                    settingsCoordinator.makeSettingsView()
                }
            }
        }
    }
}
