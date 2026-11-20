import SwiftUI

struct SettingsView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Not available"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Not available"

    var body: some View {
        Form {
            Section("App") {
                LabeledContent("Name", value: "Series Atlas")
                LabeledContent("Version", value: version)
                LabeledContent("Build", value: build)
            }

            Section("Data source") {
                Text("TV data provided by TVmaze under CC BY-SA.")
                if let url = URL(string: "https://www.tvmaze.com") {
                    Link("TVmaze", destination: url)
                }
                if let url = URL(string: "https://www.tvmaze.com/api#licensing") {
                    Link("API terms and licensing", destination: url)
                }
            }
        }
        .accessibilityIdentifier("settings.form")
        .navigationTitle("Settings")
    }
}
