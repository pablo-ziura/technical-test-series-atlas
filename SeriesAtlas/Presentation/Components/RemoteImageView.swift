import SwiftUI

struct RemoteImageView: View {
    enum ContentKind {
        case show
        case person

        var placeholderSymbol: String {
            switch self {
            case .show: "tv"
            case .person: "person.crop.rectangle"
            }
        }
    }

    enum Presentation {
        case thumbnail
        case detail

        var size: CGSize {
            switch self {
            case .thumbnail: UIConstants.Images.thumbnailSize
            case .detail: UIConstants.Images.detailImageSize
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .thumbnail: UIConstants.Corners.thumbnailCornerRadius
            case .detail: UIConstants.Corners.detailImageCornerRadius
            }
        }

        var contentMode: ContentMode {
            switch self {
            case .thumbnail: .fill
            case .detail: .fit
            }
        }

        var placeholderSymbolSize: CGFloat {
            switch self {
            case .thumbnail: UIConstants.Images.thumbnailSymbolSize
            case .detail: UIConstants.Images.detailSymbolSize
            }
        }
    }

    let url: URL?
    let kind: ContentKind
    let presentation: Presentation

    var body: some View {
        AsyncImage(url: url) { phase in
            RemoteImageContent(
                phase: phase,
                hasURL: url != nil,
                kind: kind,
                presentation: presentation
            )
        }
    }
}
