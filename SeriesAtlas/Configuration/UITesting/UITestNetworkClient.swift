import Foundation
import SeriesAtlasNetwork

// El actor serializa el fallo inicial de Retry para mantener el escenario aislado en cada lanzamiento.
actor UITestNetworkClient: NetworkClientProtocol {
    enum Scenario: String {
        case standard
        case retry
    }

    private let scenario: Scenario
    private let showsSearchPath: String
    private let peopleSearchPath: String
    private var hasFailedAtlasSearch = false

    init(scenario: Scenario, showsSearchPath: String, peopleSearchPath: String) {
        self.scenario = scenario
        self.showsSearchPath = showsSearchPath
        self.peopleSearchPath = peopleSearchPath
    }

    func get<Response: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> Response {
        try Task.checkCancellation()

        let response: String
        switch (endpoint, params?["q"]) {
        case (showsSearchPath, "Atlas"):
            if scenario == .retry, !hasFailedAtlasSearch {
                hasFailedAtlasSearch = true
                throw URLError(.notConnectedToInternet)
            }
            response = UITestResponses.shows
        case (showsSearchPath, "Orbit"), (showsSearchPath, "Edited"):
            response = UITestResponses.otherShows
        case (showsSearchPath, "Missing"):
            response = "[]"
        case (peopleSearchPath, "Alex"):
            response = UITestResponses.people
        default:
            throw URLError(.badURL)
        }

        return try JSONDecoder().decode(Response.self, from: Data(response.utf8))
    }
}
