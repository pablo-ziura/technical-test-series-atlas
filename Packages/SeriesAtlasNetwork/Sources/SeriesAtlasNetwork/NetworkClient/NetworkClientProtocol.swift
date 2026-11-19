import Foundation

public protocol NetworkClientProtocol: Sendable {
    func get<Response: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> Response
}

public extension NetworkClientProtocol {
    func get<Response: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]? = nil
    ) async throws -> Response {
        try await get(endpoint: endpoint, params: params, headers: nil)
    }

    func get<Response: Decodable & Sendable>(
        endpoint: String,
        headers: [String: String]?
    ) async throws -> Response {
        try await get(endpoint: endpoint, params: nil, headers: headers)
    }
}
