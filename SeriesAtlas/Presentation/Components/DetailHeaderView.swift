import SwiftUI

struct DetailHeaderView: View {
    let name: String
    let imageURL: URL?
    let kind: RemoteImageView.ContentKind

    var body: some View {
        VStack(spacing: UIConstants.Spacing.headerContentSpacing) {
            RemoteImageView(url: imageURL, kind: kind, presentation: .detail)

            Text(name)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}
