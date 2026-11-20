import SwiftUI

struct PeopleSearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PeopleSearchViewModel.self) private var viewModel

    var body: some View {
        List {
            if case let .results(people) = viewModel.state {
                ForEach(people) { person in
                    Button {
                        router.showDetails(for: person)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(person.name)
                            Text(person.country ?? "Not available")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("people.result.\(person.id)")
                }
            }
        }
        .overlay {
            SearchStatusView(
                state: viewModel.state,
                query: viewModel.query,
                title: "People",
                retry: viewModel.retry
            )
        }
        .navigationTitle("People")
        .searchable(
            text: viewModel.bindable.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search people"
        )
    }
}
