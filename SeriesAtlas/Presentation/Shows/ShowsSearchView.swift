import SwiftUI

struct ShowsSearchView: View {
    @Environment(ShowsSearchViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: .zero) {
            SearchInputView(
                query: viewModel.bindable.query,
                placeholder: .searchShowsTitle,
                search: viewModel.search
            )

            List {
                if case let .results(shows) = viewModel.state {
                    ForEach(shows) { show in
                        NavigationLink(value: ShowsRoute.detail(show)) {
                            SearchResultRow(name: show.name, imageURL: show.imageURL, kind: .show) {
                                Text(show.language ?? String(localized: .commonNotAvailable))
                                if !show.genres.isEmpty {
                                    Text(show.genres.joined(separator: ", "))
                                }
                                if let rating = show.rating {
                                    Label {
                                        Text(rating.formatted())
                                    } icon: {
                                        Image(systemName: "star.fill")
                                    }
                                    .accessibilityLabel(Text(.accessibilityRating(rating: rating.formatted())))
                                }
                            }
                        }
                        .accessibilityIdentifier("shows.result.\(show.id)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                SearchStatusView(
                    state: viewModel.state,
                    query: viewModel.submittedQuery,
                    idleTitle: .searchShowsTitle,
                    retry: viewModel.retry
                )
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(.navigationShows)
    }
}

#Preview("Shows") {
    UIPreviewData.makeCoordinator().makeRootView()
}
