import SwiftUI

struct RemoteImagePreviewGallery: View {
    enum Sample: CaseIterable {
        case loading
        case loaded
        case missing
        case failed

        var title: LocalizedStringResource {
            switch self {
            case .loading: .imageLoading
            case .loaded: .imageLoaded
            case .missing: .imageMissing
            case .failed: .imageFailed
            }
        }

        @MainActor
        var phase: AsyncImagePhase {
            switch self {
            case .loading, .missing: .empty
            case .loaded: .success(Image(.appLogo))
            case .failed: .failure(URLError(.cannotDecodeContentData))
            }
        }
    }

    let kind: RemoteImageView.ContentKind

    var body: some View {
        List {
            ForEach(Sample.allCases, id: \.self) { sample in
                Section(sample.title) {
                    HStack(alignment: .top, spacing: UIConstants.Spacing.rowContentSpacing) {
                        RemoteImageContent(phase: sample.phase, hasURL: sample != .missing, kind: kind, presentation: .thumbnail)
                        RemoteImageContent(phase: sample.phase, hasURL: sample != .missing, kind: kind, presentation: .detail)
                    }
                }
            }
        }
    }
}

#Preview("Show images") {
    RemoteImagePreviewGallery(kind: .show)
}
