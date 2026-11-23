import Foundation

struct AppConfiguration {
    struct API {
        let baseURL: URL
        let showsSearchPath: String
        let peopleSearchPath: String
    }

    struct Links {
        let tvmazeURL: URL
        let licensingURL: URL
    }

    enum ConfigurationError: Error, Equatable {
        case missingResource
        case invalidURL(key: String)
        case invalidSearchPath(key: String)
    }

    let api: API
    let links: Links

    init(data: Data) throws {
        let values = try PropertyListDecoder().decode(Values.self, from: data)
        let baseURL = try Self.webURL(values.api.baseURL, key: "api.baseURL")
        guard let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              components.query == nil, components.fragment == nil else {
            throw ConfigurationError.invalidURL(key: "api.baseURL")
        }

        api = API(
            baseURL: baseURL,
            showsSearchPath: try Self.searchPath(values.api.showsSearchPath, key: "api.showsSearchPath"),
            peopleSearchPath: try Self.searchPath(values.api.peopleSearchPath, key: "api.peopleSearchPath")
        )
        links = Links(
            tvmazeURL: try Self.webURL(values.links.tvmazeURL, key: "links.tvmazeURL"),
            licensingURL: try Self.webURL(values.links.licensingURL, key: "links.licensingURL")
        )
    }

    static func load(bundle: Bundle = .main) throws -> AppConfiguration {
        guard let url = bundle.url(forResource: "AppConfiguration", withExtension: "plist") else {
            throw ConfigurationError.missingResource
        }
        return try AppConfiguration(data: Data(contentsOf: url))
    }

    private static func webURL(_ value: String, key: String) throws -> URL {
        guard value == value.trimmingCharacters(in: .whitespacesAndNewlines),
              let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              let url = components.url else {
            throw ConfigurationError.invalidURL(key: key)
        }
        return url
    }

    private static func searchPath(_ value: String, key: String) throws -> String {
        guard value == value.trimmingCharacters(in: .whitespacesAndNewlines),
              let components = URLComponents(string: value),
              components.scheme == nil, components.host == nil,
              components.query == nil, components.fragment == nil,
              !components.path.isEmpty, !components.path.hasPrefix("/"),
              !components.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }) else {
            throw ConfigurationError.invalidSearchPath(key: key)
        }
        return value
    }

    private struct Values: Codable {
        struct API: Codable {
            let baseURL: String
            let showsSearchPath: String
            let peopleSearchPath: String
        }

        struct Links: Codable {
            let tvmazeURL: String
            let licensingURL: String
        }

        let api: API
        let links: Links
    }
}
