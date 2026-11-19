import Foundation
@testable import SeriesAtlasNetwork
import Testing

@Suite("NetworkClient")
struct NetworkClientTests {
    private struct Response: Codable, Equatable, Sendable {
        let value: String
    }

    @Test("GET decodes successful HTTP responses", arguments: [200, 201, 299])
    func decodesSuccessfulResponse(statusCode: Int) async throws {
        let transport = HTTPTransportStub(result: .success(try response(statusCode: statusCode)))
        let client: any NetworkClientProtocol = try makeClient(transport: transport)

        let result: Response = try await client.get(endpoint: "shows")

        #expect(result == Response(value: "OK"))
    }

    @Test("GET preserves query values including Unicode, reserved characters and empty strings")
    func encodesQueryParameters() async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client: any NetworkClientProtocol = try makeClient(transport: transport)
        let params = ["q": "  Café & Tea+?/#% 📺  ", "empty": "", "filter&kind": "A=B"]

        let _: Response = try await client.get(endpoint: "search/shows", params: params)

        let requests = await transport.requests
        let url = try #require(requests.first?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)
        #expect(Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") }) == params)
        #expect(components.percentEncodedQuery?.contains("%2B") == true)
        #expect(url.fragment == nil)
    }

    @Test("GET sends supplied headers without a body")
    func sendsHeaders() async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client: any NetworkClientProtocol = try makeClient(transport: transport)

        let _: Response = try await client.get(endpoint: "shows", headers: ["Accept": "application/json", "X-Request-ID": "123"])

        let requests = await transport.requests
        let request = try #require(requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "X-Request-ID") == "123")
        #expect(request.httpBody == nil)
        #expect(request.url?.query == nil)
    }

    @Test("An empty parameter dictionary does not add an empty query")
    func omitsEmptyQuery() async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client: any NetworkClientProtocol = try makeClient(transport: transport)

        let _: Response = try await client.get(endpoint: "shows", params: [:])

        let requests = await transport.requests
        #expect(requests.first?.url?.absoluteString == "https://api.example.com/shows")
    }

    @Test("GET supports parameters and headers together")
    func sendsParametersAndHeaders() async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client: any NetworkClientProtocol = try makeClient(transport: transport)

        let _: Response = try await client.get(endpoint: "shows", params: ["q": "test"], headers: ["X-Test": "value"])

        let requests = await transport.requests
        #expect(requests.first?.url?.query == "q=test")
        #expect(requests.first?.value(forHTTPHeaderField: "X-Test") == "value")
    }

    @Test("GET joins relative endpoints with the base path", arguments: [
        ("https://api.example.com", "/search/shows"),
        ("https://api.example.com/", "/search/shows"),
        ("https://api.example.com/v1", "/v1/search/shows"),
        ("https://api.example.com/v1/", "/v1/search/shows"),
        ("https://api.example.com/my%20api/", "/my api/search/shows"),
    ])
    func joinsBasePath(baseURL: String, expectedPath: String) async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client = try makeClient(baseURL: baseURL, transport: transport)

        let _: Response = try await client.get(endpoint: "search/shows")

        let requests = await transport.requests
        #expect(requests.first?.url?.path == expectedPath)
        #expect(requests.first?.url?.host == "api.example.com")
    }

    @Test("Invalid base URLs fail before transport", arguments: [
        "file:///tmp/api", "ftp://api.example.com", "/relative", "https:///shows",
        "https://api.example.com?q=test", "https://api.example.com#fragment",
    ])
    func rejectsInvalidBaseURL(baseURL: String) async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client = try makeClient(baseURL: baseURL, transport: transport)

        await #expect(throws: NetworkError.invalidURL) {
            let _: Response = try await client.get(endpoint: "shows")
        }
        #expect(await transport.requests.isEmpty)
    }

    @Test("Only relative endpoint paths are accepted", arguments: [
        "https://other.example.com/shows", "//other.example.com/shows", "/shows",
        "shows?q=test", "shows#fragment", "../shows", "shows/../other", "", "shows/%2E%2E/other",
    ])
    func rejectsInvalidEndpoint(endpoint: String) async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client = try makeClient(transport: transport)

        await #expect(throws: NetworkError.invalidURL) {
            let _: Response = try await client.get(endpoint: endpoint)
        }
        #expect(await transport.requests.isEmpty)
    }

    @Test("Non-success status is reported before decoding", arguments: [199, 300, 401, 404, 429, 500])
    func rejectsHTTPStatus(statusCode: Int) async throws {
        let transport = HTTPTransportStub(result: .success(try response(statusCode: statusCode, body: "invalid JSON")))
        let client = try makeClient(transport: transport)

        await #expect(throws: NetworkError.httpStatus(statusCode)) {
            let _: Response = try await client.get(endpoint: "shows")
        }
    }

    @Test("Non-HTTP responses are rejected")
    func rejectsNonHTTPResponse() async throws {
        let url = try #require(URL(string: "https://api.example.com/shows"))
        let nonHTTP = URLResponse(url: url, mimeType: "application/json", expectedContentLength: 0, textEncodingName: nil)
        let transport = HTTPTransportStub(result: .success((Data(), nonHTTP)))
        let client = try makeClient(transport: transport)

        await #expect(throws: NetworkError.invalidResponse) {
            let _: Response = try await client.get(endpoint: "shows")
        }
    }

    @Test("Malformed JSON retains the decoding error")
    func propagatesDecodingError() async throws {
        let transport = HTTPTransportStub(result: .success(try response(body: "invalid JSON")))
        let client = try makeClient(transport: transport)

        await #expect(throws: DecodingError.self) {
            let _: Response = try await client.get(endpoint: "shows")
        }
    }

    @Test("Empty successful bodies retain the decoding error", arguments: [200, 204])
    func rejectsEmptyBody(statusCode: Int) async throws {
        let transport = HTTPTransportStub(result: .success(try response(statusCode: statusCode, body: "")))
        let client = try makeClient(transport: transport)

        await #expect(throws: DecodingError.self) {
            let _: Response = try await client.get(endpoint: "shows")
        }
    }

    @Test("Transport errors retain their original code", arguments: [URLError.Code.notConnectedToInternet, .timedOut])
    func propagatesTransportError(code: URLError.Code) async throws {
        let transport = HTTPTransportStub(result: .failure(URLError(code)))
        let client = try makeClient(transport: transport)

        do {
            let _: Response = try await client.get(endpoint: "shows")
            Issue.record("Expected a transport error")
        } catch let error as URLError {
            #expect(error.code == code)
        }
    }

    @Test("URLSession cancellation becomes CancellationError")
    func normalizesURLCancellation() async throws {
        let transport = HTTPTransportStub(result: .failure(URLError(.cancelled)))
        let client = try makeClient(transport: transport)

        await #expect(throws: CancellationError.self) {
            let _: Response = try await client.get(endpoint: "shows")
        }
    }

    @Test("A task cancelled before GET never reaches transport")
    func cancelsBeforeTransport() async throws {
        let transport = HTTPTransportStub(result: .success(try response()))
        let client = try makeClient(transport: transport)
        let gate = StartGate()
        let task = Task<Response, any Error> {
            await gate.wait()
            return try await client.get(endpoint: "shows")
        }

        task.cancel()
        await gate.open()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await transport.requests.isEmpty)
    }

    @Test("Cancelling GET reaches the suspended transport")
    func cancelsInFlightTransport() async throws {
        try await withControlledRequests(cancellationBehavior: .cooperative) { transport, tasks in
            let task = try #require(tasks.first)
            _ = try await transport.waitUntilRequested()

            task.cancel()

            await #expect(throws: CancellationError.self) { try await task.value }
            #expect(await transport.cancelledCount == 1)
        }
    }

    @Test("Cancellation discards a successful late response")
    func rejectsSuccessAfterCancellation() async throws {
        try await withControlledRequests(cancellationBehavior: .ignoring) { transport, tasks in
            let task = try #require(tasks.first)
            let requests = try await transport.waitUntilRequested()
            let request = try #require(requests.first)

            task.cancel()
            try await transport.complete(id: request.id, with: .success(try response()))

            await #expect(throws: CancellationError.self) { try await task.value }
        }
    }

    @Test("Cancellation takes precedence over a late transport failure")
    func rejectsErrorAfterCancellation() async throws {
        try await withControlledRequests(cancellationBehavior: .ignoring) { transport, tasks in
            let task = try #require(tasks.first)
            let requests = try await transport.waitUntilRequested()
            let request = try #require(requests.first)

            task.cancel()
            try await transport.complete(id: request.id, with: .failure(URLError(.timedOut)))

            await #expect(throws: CancellationError.self) { try await task.value }
        }
    }

    @Test("Concurrent searches at the same endpoint complete independently and out of order")
    func supportsConcurrentRequests() async throws {
        try await withControlledRequests(
            cancellationBehavior: .ignoring,
            params: [["q": "first"], ["q": "second"]]
        ) { transport, tasks in
            try #require(tasks.count == 2)
            let requests = try await transport.waitUntilRequested(count: 2)
            try #require(requests.allSatisfy { $0.request.url?.path == "/search/shows" })
            let first = try #require(requests.first { $0.request.url?.query == "q=first" })
            let second = try #require(requests.first { $0.request.url?.query == "q=second" })

            try await transport.complete(id: second.id, with: .success(try response(body: #"{"value":"second"}"#)))
            #expect(try await tasks[1].value == Response(value: "second"))
            #expect(await transport.pendingCount == 1)
            try await transport.complete(id: first.id, with: .success(try response(body: #"{"value":"first"}"#)))
            #expect(try await tasks[0].value == Response(value: "first"))
            #expect(await transport.pendingCount == 0)
        }
    }

    private func withControlledRequests(
        cancellationBehavior: ControlledHTTPTransport.CancellationBehavior,
        params: [[String: String]] = [[:]],
        operation: @escaping @Sendable (ControlledHTTPTransport, [Task<Response, any Error>]) async throws -> Void
    ) async throws {
        let transport = ControlledHTTPTransport(cancellationBehavior: cancellationBehavior)
        let client = try makeClient(transport: transport)
        let tasks = params.map { values in
            Task<Response, any Error> { try await client.get(endpoint: "search/shows", params: values) }
        }

        let outcome: Result<Void, any Error>
        do {
            try await withTaskCancellationHandler {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        do {
                            try await operation(transport, tasks)
                        } catch {
                            await transport.close()
                            throw error
                        }
                        await transport.close()
                    }
                    group.addTask {
                        // Failure deadline only; successful tests do not wait for it.
                        try await Task.sleep(for: .seconds(5))
                        await transport.close(throwing: .timedOut)
                        throw ControlledHTTPTransport.Failure.timedOut
                    }
                    defer { group.cancelAll() }
                    _ = try await group.next()
                }
            } onCancel: {
                Task { await transport.close() }
            }
            outcome = .success(())
        } catch {
            outcome = .failure(error)
        }

        await transport.close()
        tasks.forEach { $0.cancel() }
        for task in tasks { _ = await task.result }
        if case .timedOut? = await transport.closedReason {
            throw ControlledHTTPTransport.Failure.timedOut
        }
        try outcome.get()
    }

    private func makeClient(
        baseURL: String = "https://api.example.com",
        transport: any HTTPTransport
    ) throws -> NetworkClient {
        NetworkClient(baseURL: try #require(URL(string: baseURL)), transport: transport)
    }

    private func response(
        statusCode: Int = 200,
        body: String = #"{"value":"OK"}"#
    ) throws -> (Data, URLResponse) {
        let url = try #require(URL(string: "https://api.example.com/shows"))
        let response = try #require(HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil))
        return (Data(body.utf8), response)
    }
}
