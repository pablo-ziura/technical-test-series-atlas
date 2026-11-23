import SwiftUI

struct RemoteImageContent: View {
    let phase: AsyncImagePhase
    let hasURL: Bool
    let kind: RemoteImageView.ContentKind
    let presentation: RemoteImageView.Presentation

    var body: some View {
        Color(uiColor: .tertiarySystemFill)
            .frame(width: presentation.size.width, height: presentation.size.height)
            .overlay {
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: presentation.contentMode)
                        .frame(width: presentation.size.width, height: presentation.size.height)
                        .accessibilityIgnoresInvertColors()
                case .empty:
                    if hasURL {
                        ProgressView()
                    } else {
                        placeholder(symbol: kind.placeholderSymbol)
                            .foregroundStyle(.secondary)
                    }
                case .failure:
                    placeholder(symbol: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                @unknown default:
                    placeholder(symbol: kind.placeholderSymbol)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: presentation.cornerRadius))
            .accessibilityHidden(true)
    }

    private func placeholder(symbol: String) -> some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: presentation.placeholderSymbolSize, height: presentation.placeholderSymbolSize)
    }
}
