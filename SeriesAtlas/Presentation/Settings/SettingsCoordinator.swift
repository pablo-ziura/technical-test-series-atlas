import SwiftUI

@MainActor
final class SettingsCoordinator {
    private let tvmazeURL: URL
    private let licensingURL: URL

    init(tvmazeURL: URL, licensingURL: URL) {
        self.tvmazeURL = tvmazeURL
        self.licensingURL = licensingURL
    }

    func makeSettingsView() -> some View {
        SettingsView(tvmazeURL: tvmazeURL, licensingURL: licensingURL)
    }
}
