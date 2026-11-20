import SwiftUI

struct PersonDetailView: View {
    let person: Person

    var body: some View {
        List {
            Section {
                DetailImageView(url: person.imageURL, placeholder: "person.crop.rectangle")
            }

            Section("Information") {
                LabeledContent("Name", value: person.name)
                LabeledContent("Country", value: person.country ?? "Not available")
                LabeledContent("Gender", value: person.gender ?? "Not available")
                LabeledContent("Birthday", value: person.birthday ?? "Not available")
                if let deathday = person.deathday {
                    LabeledContent("Deathday", value: deathday)
                }
            }

            Section("Source") {
                Link("View on TVmaze", destination: person.tvmazeURL)
            }
        }
        .accessibilityIdentifier("person.detail")
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
