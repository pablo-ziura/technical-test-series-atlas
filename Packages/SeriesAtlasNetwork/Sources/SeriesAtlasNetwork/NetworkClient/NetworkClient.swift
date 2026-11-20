import Foundation

public struct NetworkClient: NetworkClientProtocol {
    private let baseURL: URL
    private let transport: any HTTPTransport

    public init(baseURL: URL, session: URLSession) {
        self.init(baseURL: baseURL, transport: URLSessionTransport(session: session))
    }

    init(baseURL: URL, transport: any HTTPTransport) {
        self.baseURL = baseURL
        self.transport = transport
    }

    @concurrent
    public func get<Response: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> Response {
        do {
            try Task.checkCancellation()
            var request = URLRequest(url: try makeURL(endpoint: endpoint, params: params))
            request.httpMethod = "GET"
            headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

            let (data, response) = try await transport.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200..<300).contains(response.statusCode) else {
                throw NetworkError.httpStatus(response.statusCode)
            }

            let decoded = try JSONDecoder().decode(Response.self, from: data)
            try Task.checkCancellation()
            return decoded
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw error
        }
    }

    private func makeURL(endpoint: String, params: [String: String]?) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host, !host.isEmpty,
              components.query == nil, components.fragment == nil,
              let relative = URLComponents(string: endpoint),
              relative.scheme == nil, relative.host == nil,
              relative.query == nil, relative.fragment == nil,
              !relative.path.isEmpty, !relative.path.hasPrefix("/"),
              !relative.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }) else {
            throw NetworkError.invalidURL
        }

        let basePath = components.percentEncodedPath
        let prefix = basePath.hasSuffix("/") ? basePath : basePath + "/"
        components.percentEncodedPath = prefix + relative.percentEncodedPath
        if let params, !params.isEmpty {
            components.queryItems = params.sorted(by: { $0.key < $1.key }).map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        // Form-style query parsers otherwise interpret a literal plus as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")

        guard let url = components.url else { throw NetworkError.invalidURL }
        return url
    }
}
