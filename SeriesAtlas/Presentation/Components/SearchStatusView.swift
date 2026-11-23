import SwiftUI

struct SearchStatusView<Item: Sendable>: View {
    let state: SearchState<Item>
    let query: String
    let idleTitle: LocalizedStringResource
    let retry: () -> Void

    var body: some View {
        if case .results = state {
            EmptyView()
        } else {
            ScrollView {
                statusContent
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .defaultScrollAnchor(.center, for: .alignment)
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch state {
        case .idle:
            ContentUnavailableView(
                idleTitle,
                systemImage: "magnifyingglass",
                description: Text(.searchInstructions)
            )
        case .loading:
            ProgressView(.searchLoading(query: query))
                .controlSize(.large)
                .multilineTextAlignment(.center)
        case .empty:
            ContentUnavailableView(
                .searchEmptyTitle,
                systemImage: "magnifyingglass",
                description: Text(.searchEmptyDescription(query: query))
            )
        case let .failure(message):
            ContentUnavailableView {
                Label(.searchUnavailable, systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button(.commonRetry, action: retry)
                    .buttonStyle(.borderedProminent)
            }
        case .results:
            EmptyView()
        }
    }
}

#Preview("Search error") {
    SearchStatusView<Show>(
        state: .failure(String(localized: .searchShowsError)),
        query: "Atlas",
        idleTitle: .searchShowsTitle,
        retry: {}
    )
    .tint(.blue)
}
