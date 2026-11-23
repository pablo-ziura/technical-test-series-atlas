import SwiftUI

struct SearchResultRow<Metadata: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let name: String
    let imageURL: URL?
    let kind: RemoteImageView.ContentKind
    @ViewBuilder var metadata: () -> Metadata

    private var layout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: UIConstants.Spacing.rowContentSpacing))
        } else {
            AnyLayout(HStackLayout(alignment: .top, spacing: UIConstants.Spacing.rowContentSpacing))
        }
    }

    var body: some View {
        layout {
            RemoteImageView(url: imageURL, kind: kind, presentation: .thumbnail)

            VStack(alignment: .leading, spacing: UIConstants.Spacing.metadataSpacing) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                metadata()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, UIConstants.Spacing.metadataSpacing)
        .accessibilityElement(children: .combine)
    }
}
