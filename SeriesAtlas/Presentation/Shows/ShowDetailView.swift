import SwiftUI

struct ShowDetailView: View {
    let show: Show

    var body: some View {
        List {
            Section {
                DetailImageView(url: show.imageURL, placeholder: "tv")
            }

            Section("Information") {
                LabeledContent("Name", value: show.name)
                LabeledContent("Genres", value: show.genres.isEmpty ? "Not available" : show.genres.joined(separator: ", "))
                LabeledContent("Language", value: show.language ?? "Not available")
                LabeledContent("Rating", value: show.rating.map { $0.formatted() } ?? "Not available")
            }

            Section("Summary") {
                Text(show.summary ?? "Not available")
            }

            Section("Source") {
                Link("View on TVmaze", destination: show.tvmazeURL)
            }
        }
        .accessibilityIdentifier("show.detail")
        .navigationTitle(show.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
