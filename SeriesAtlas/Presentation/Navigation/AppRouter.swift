import Foundation
import Observation

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .shows
    var showsPath: [ShowsRoute] = []
    var peoplePath: [PeopleRoute] = []

    func showDetails(for show: Show) {
        showsPath.append(.detail(show))
    }

    func showDetails(for person: Person) {
        peoplePath.append(.detail(person))
    }

    func popShows() {
        guard !showsPath.isEmpty else { return }
        showsPath.removeLast()
    }

    func popPeople() {
        guard !peoplePath.isEmpty else { return }
        peoplePath.removeLast()
    }
}
