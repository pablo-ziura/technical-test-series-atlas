import Foundation

enum UIConstants {
    enum Images {
        static let thumbnailSize = CGSize(width: 60, height: 90)
        static let detailImageSize = CGSize(width: 160, height: 240)
        static let thumbnailSymbolSize: CGFloat = 28
        static let detailSymbolSize: CGFloat = 40
        static let appIconSize: CGFloat = 60
    }

    enum Spacing {
        static let metadataSpacing: CGFloat = 4
        static let rowContentSpacing: CGFloat = 12
        static let headerContentSpacing: CGFloat = 16
    }

    enum Corners {
        static let thumbnailCornerRadius: CGFloat = 8
        static let detailImageCornerRadius: CGFloat = 12
        static let appIconCornerRadius: CGFloat = 12
    }
}
