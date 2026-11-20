import Foundation
import SwiftUI

@MainActor
final class PeopleCoordinator {
    let viewModel: PeopleSearchViewModel

    init(searchPeopleUseCase: SearchPeopleUseCaseProtocol) {
        viewModel = PeopleSearchViewModel(searchPeopleUseCase: searchPeopleUseCase)
    }

    func makeSearchView() -> some View {
        PeopleSearchView()
            .environment(viewModel)
    }

    func destination(for route: PeopleRoute) -> some View {
        switch route {
        case let .detail(person):
            PersonDetailView(person: person)
        }
    }
}
