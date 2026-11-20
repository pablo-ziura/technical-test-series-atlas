import SwiftUI

struct ShowsSearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ShowsSearchViewModel.self) private var viewModel

    var body: some View {
        List {
            if case let .results(shows) = viewModel.state {
                ForEach(shows) { show in
                    Button {
                        router.showDetails(for: show)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(show.name)
                            Text(show.language ?? "Not available")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("shows.result.\(show.id)")
                }
            }
        }
        .overlay {
            SearchStatusView(
                state: viewModel.state,
                query: viewModel.query,
                title: "Shows",
                retry: viewModel.retry
            )
        }
        .navigationTitle("Shows")
        .searchable(
            text: viewModel.bindable.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search shows"
        )
    }
}
