import SwiftUI

struct SettingsView: View {
    let tvmazeURL: URL
    let licensingURL: URL

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? String(localized: .commonNotAvailable)
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? String(localized: .commonNotAvailable)

    private var headerLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: UIConstants.Spacing.headerContentSpacing))
        } else {
            AnyLayout(HStackLayout(spacing: UIConstants.Spacing.headerContentSpacing))
        }
    }

    var body: some View {
        Form {
            Section {
                headerLayout {
                    Image(.appLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIConstants.Images.appIconSize, height: UIConstants.Images.appIconSize)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.Corners.appIconCornerRadius))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: UIConstants.Spacing.metadataSpacing) {
                        Text(.appName)
                            .font(.headline)
                        Text(.settingsTagline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical)
            }

            Section(.settingsApp) {
                LabeledContent(String(localized: .settingsVersion), value: version)
                LabeledContent(String(localized: .settingsBuild), value: build)
            }

            Section(.settingsDataSource) {
                Text(.settingsAttribution)
                Link(destination: tvmazeURL) {
                    Label(.settingsTvmaze, systemImage: "globe")
                }
                Link(destination: licensingURL) {
                    Label(.settingsLicensing, systemImage: "doc.text")
                }
            }
        }
        .accessibilityIdentifier("settings.form")
        .navigationTitle(.navigationSettings)
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView(tvmazeURL: UIPreviewData.sourceURL, licensingURL: UIPreviewData.sourceURL)
    }
    .tint(.blue)
}
