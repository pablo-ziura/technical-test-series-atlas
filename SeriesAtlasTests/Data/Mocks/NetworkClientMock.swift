import Foundation
import SeriesAtlasNetwork

@MainActor
final class NetworkClientMock: NetworkClientProtocol {
    var dataToReturn = Data("[]".utf8)
    var errorToThrow: (any Error)?
    var onGet: (() -> Void)?
    private(set) var endpoints: [String] = []
    private(set) var params: [String: String]?
    private(set) var headers: [String: String]?

    func get<Response: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> Response {
        endpoints.append(endpoint)
        self.params = params
        self.headers = headers
        onGet?()
        if let errorToThrow { throw errorToThrow }
        return try JSONDecoder().decode(Response.self, from: dataToReturn)
    }
}
