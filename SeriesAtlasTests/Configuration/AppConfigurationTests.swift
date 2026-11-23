import Foundation
@testable import SeriesAtlas
import Testing

final class AppConfigurationTests {
    @Test
    func loadsBundledConfiguration() {
        #expect(throws: Never.self) {
            _ = try AppConfiguration.load()
        }
    }

    @Test
    func decodesConfiguredURLsAndSearchPaths() throws {
        let configuration = try AppConfiguration(data: makeData(values))

        #expect(configuration.api.baseURL.absoluteString == "https://api.example.com/v2")
        #expect(configuration.api.showsSearchPath == "catalog/shows")
        #expect(configuration.api.peopleSearchPath == "catalog/people")
        #expect(configuration.links.tvmazeURL.absoluteString == "https://example.com")
        #expect(configuration.links.licensingURL.absoluteString == "https://example.com/terms#license")
    }

    @Test
    func rejectsBundleWithoutConfiguration() {
        let bundle = Bundle(for: AppConfigurationTests.self)

        #expect(throws: AppConfiguration.ConfigurationError.missingResource) {
            _ = try AppConfiguration.load(bundle: bundle)
        }
    }

    @Test
    func rejectsIncompleteConfiguration() throws {
        var incompleteValues = values
        incompleteValues["links"]?["licensingURL"] = nil
        let data = try makeData(incompleteValues)

        #expect(throws: DecodingError.self) {
            _ = try AppConfiguration(data: data)
        }
    }

    @Test(arguments: [
        ("api", "baseURL", "/api"),
        ("api", "baseURL", "https://api.example.com?query=test"),
        ("api", "baseURL", "https://api.example.com#fragment"),
        ("links", "tvmazeURL", "ftp://example.com"),
        ("links", "licensingURL", "https:///terms"),
    ])
    func rejectsInvalidURLs(section: String, key: String, value: String) throws {
        var invalidValues = values
        invalidValues[section]?[key] = value
        let data = try makeData(invalidValues)

        #expect(throws: AppConfiguration.ConfigurationError.invalidURL(key: "\(section).\(key)")) {
            _ = try AppConfiguration(data: data)
        }
    }

    @Test(arguments: ["", "https://example.com/shows", "/shows", "shows?q=test", "../shows"])
    func rejectsInvalidSearchPaths(path: String) throws {
        var invalidValues = values
        invalidValues["api"]?["showsSearchPath"] = path
        let data = try makeData(invalidValues)

        #expect(throws: AppConfiguration.ConfigurationError.invalidSearchPath(key: "api.showsSearchPath")) {
            _ = try AppConfiguration(data: data)
        }
    }

    private var values: [String: [String: String]] {
        [
            "api": [
                "baseURL": "https://api.example.com/v2",
                "showsSearchPath": "catalog/shows",
                "peopleSearchPath": "catalog/people",
            ],
            "links": [
                "tvmazeURL": "https://example.com",
                "licensingURL": "https://example.com/terms#license",
            ],
        ]
    }

    private func makeData(_ values: [String: [String: String]]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
    }
}
