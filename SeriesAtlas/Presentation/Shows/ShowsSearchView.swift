import SwiftUI

struct ShowsSearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ShowsSearchViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search shows", text: viewModel.bindable.query)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { viewModel.search() }

                Button("Search", action: viewModel.search)
                    .buttonStyle(.borderedProminent)
            }
            .padding()

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
                    query: viewModel.submittedQuery,
                    title: "Shows",
                    retry: viewModel.retry
                )
            }
        }
        .navigationTitle("Shows")
    }
}
