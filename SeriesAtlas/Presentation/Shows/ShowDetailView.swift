import SwiftUI

struct ShowDetailView: View {
    let show: Show

    var body: some View {
        List {
            Section {
                DetailHeaderView(name: show.name, imageURL: show.imageURL, kind: .show)
            }

            Section(.detailInformation) {
                LabeledContent(String(localized: .detailGenres), value: show.genres.isEmpty ? String(localized: .commonNotAvailable) : show.genres.joined(separator: ", "))
                LabeledContent(String(localized: .detailLanguage), value: show.language ?? String(localized: .commonNotAvailable))
                LabeledContent(String(localized: .detailRating), value: show.rating.map { $0.formatted() } ?? String(localized: .commonNotAvailable))
            }

            Section(.detailSummary) {
                Text(show.summary ?? String(localized: .commonNotAvailable))
            }

            Section(.detailSource) {
                Link(destination: show.tvmazeURL) {
                    Label(.detailViewOnTVmaze, systemImage: "arrow.up.right.square")
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("show.detail")
        .navigationTitle(show.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Show detail") {
    NavigationStack {
        ShowDetailView(show: UIPreviewData.show)
    }
    .tint(.blue)
}
