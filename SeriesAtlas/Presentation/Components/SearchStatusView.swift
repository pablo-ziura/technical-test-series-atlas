import SwiftUI

struct SearchStatusView<Item: Sendable>: View {
    let state: SearchState<Item>
    let query: String
    let title: String
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            ContentUnavailableView(
                "Search \(title)",
                systemImage: "magnifyingglass",
                description: Text("Enter a name to start searching.")
            )
        case .loading:
            ProgressView("Searching…")
        case .empty:
            ContentUnavailableView.search(text: query)
        case let .failure(message):
            ContentUnavailableView {
                Label("Search unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry", action: retry)
            }
        case .results:
            EmptyView()
        }
    }
}
