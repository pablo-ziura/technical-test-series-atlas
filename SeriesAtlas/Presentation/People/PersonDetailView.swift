import SwiftUI

struct PersonDetailView: View {
    let person: Person

    var body: some View {
        List {
            Section {
                DetailHeaderView(name: person.name, imageURL: person.imageURL, kind: .person)
            }

            Section(.detailInformation) {
                LabeledContent(String(localized: .detailCountry), value: person.country ?? String(localized: .commonNotAvailable))
                LabeledContent(String(localized: .detailGender), value: person.gender ?? String(localized: .commonNotAvailable))
                LabeledContent(String(localized: .detailBirthday), value: person.birthday ?? String(localized: .commonNotAvailable))
                if let deathday = person.deathday {
                    LabeledContent(String(localized: .detailDeathday), value: deathday)
                }
            }

            Section(.detailSource) {
                Link(destination: person.tvmazeURL) {
                    Label(.detailViewOnTVmaze, systemImage: "arrow.up.right.square")
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("person.detail")
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Person detail") {
    NavigationStack {
        PersonDetailView(person: UIPreviewData.person)
    }
    .tint(.blue)
}
