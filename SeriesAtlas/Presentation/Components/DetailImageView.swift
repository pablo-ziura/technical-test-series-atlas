import SwiftUI

struct DetailImageView: View {
    let url: URL?
    let placeholder: String

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFit()
            case .empty where url != nil:
                ProgressView()
            default:
                Image(systemName: placeholder)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 240)
        .accessibilityHidden(true)
    }
}
