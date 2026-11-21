import SwiftUI

struct PeopleSearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PeopleSearchViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search people", text: viewModel.bindable.query)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { viewModel.search() }

                Button("Search", action: viewModel.search)
                    .buttonStyle(.borderedProminent)
            }
            .padding()

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
                    query: viewModel.submittedQuery,
                    title: "People",
                    retry: viewModel.retry
                )
            }
        }
        .navigationTitle("People")
    }
}
