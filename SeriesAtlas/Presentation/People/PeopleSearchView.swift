import SwiftUI

struct PeopleSearchView: View {
    @Environment(PeopleSearchViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: .zero) {
            SearchInputView(
                query: viewModel.bindable.query,
                placeholder: .searchPeopleTitle,
                search: viewModel.search
            )

            List {
                if case let .results(people) = viewModel.state {
                    ForEach(people) { person in
                        NavigationLink(value: PeopleRoute.detail(person)) {
                            SearchResultRow(name: person.name, imageURL: person.imageURL, kind: .person) {
                                Text(person.country ?? String(localized: .commonNotAvailable))
                            }
                        }
                        .accessibilityIdentifier("people.result.\(person.id)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                SearchStatusView(
                    state: viewModel.state,
                    query: viewModel.submittedQuery,
                    idleTitle: .searchPeopleTitle,
                    retry: viewModel.retry
                )
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(.navigationPeople)
    }
}

#Preview("People") {
    UIPreviewData.makeCoordinator(selectedTab: .people).makeRootView()
}
