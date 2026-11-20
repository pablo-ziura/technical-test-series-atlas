import Foundation
import SwiftUI

@MainActor
final class ShowsCoordinator {
    let viewModel: ShowsSearchViewModel

    init(searchShowsUseCase: SearchShowsUseCaseProtocol) {
        viewModel = ShowsSearchViewModel(searchShowsUseCase: searchShowsUseCase)
    }

    func makeSearchView() -> some View {
        ShowsSearchView()
            .environment(viewModel)
    }

    func destination(for route: ShowsRoute) -> some View {
        switch route {
        case let .detail(show):
            ShowDetailView(show: show)
        }
    }
}
