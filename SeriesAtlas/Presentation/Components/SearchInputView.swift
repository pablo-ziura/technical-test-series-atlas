import SwiftUI

struct SearchInputView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var isFocused: Bool
    @Binding var query: String
    let placeholder: LocalizedStringResource
    let search: () -> Void

    private var layout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: UIConstants.Spacing.rowContentSpacing))
        } else {
            AnyLayout(HStackLayout(spacing: UIConstants.Spacing.rowContentSpacing))
        }
    }

    var body: some View {
        layout {
            TextField(String(localized: placeholder), text: $query)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("search.query")
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit(submitSearch)

            Button(.commonSearch, action: submitSearch)
                .accessibilityIdentifier("search.submit")
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private func submitSearch() {
        isFocused = false
        search()
    }
}
